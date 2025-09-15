import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="waypoints-map"
export default class extends Controller {
  static values = {
    startLocation: String,
    endLocation: String,
    avoidMotorways: Boolean
  }

  connect() {
    // Check if Leaflet is available
    if (typeof L === 'undefined') {
      console.error('Leaflet (L) is not available. Make sure leaflet.js is loaded.')
      this.showError('Map library is not available. Please refresh the page.')
      return
    }

    this.waypoints = []
    this.waypointCounter = 0

    this.initializeMap()
  }

  disconnect() {
    if (this.map) {
      this.map.remove()
      this.map = null
    }
  }

  async initializeMap() {
    // Initialize the map centered on the US
    this.map = L.map(this.element, {
      center: [39.8283, -98.5795], // Center of USA
      zoom: 4
    })

    // Add OpenStreetMap tile layer
    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      attribution: '© <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
    }).addTo(this.map)

    // Show loading indicator
    const loadingDiv = document.createElement('div')
    loadingDiv.className = 'absolute inset-0 bg-white bg-opacity-75 flex items-center justify-center z-50'
    loadingDiv.innerHTML = `
      <div class="text-center">
        <div class="animate-spin rounded-full h-8 w-8 border-b-2 border-blue-600 mx-auto mb-2"></div>
        <div class="text-sm text-gray-600">Loading route...</div>
      </div>
    `
    this.element.appendChild(loadingDiv)

    try {
      // Geocode the locations and display the route
      await this.displayRoute()
      this.setupMapClickListener()
    } catch (error) {
      console.error('Error displaying route:', error)
      this.showError('Unable to display route. Please check the location names.')
    } finally {
      // Remove loading indicator
      if (loadingDiv.parentNode) {
        loadingDiv.parentNode.removeChild(loadingDiv)
      }
    }
  }

  async displayRoute() {
    const startCoords = await this.geocode(this.startLocationValue)
    const endCoords = await this.geocode(this.endLocationValue)

    if (!startCoords || !endCoords) {
      throw new Error('Unable to geocode locations')
    }

    // Add markers for start and end points
    const startMarker = L.marker(startCoords, {
      icon: this.createStartIcon()
    }).addTo(this.map)
      .bindPopup(`<strong>Start:</strong><br>${this.startLocationValue}`)

    const endMarker = L.marker(endCoords, {
      icon: this.createEndIcon()
    }).addTo(this.map)
      .bindPopup(`<strong>Destination:</strong><br>${this.endLocationValue}`)

    // Store markers for later use
    this.startMarker = startMarker
    this.endMarker = endMarker

    // Get the actual driving route
    try {
      const routeData = await this.getRoute(startCoords, endCoords)

      if (routeData && routeData.geometry) {
        // Draw the actual route following roads
        // Use different color for highway-avoiding routes
        const routeColor = this.avoidMotorwaysValue ? '#10B981' : '#3B82F6' // Green for highway-free, blue for normal
        this.routeLine = L.geoJSON(routeData.geometry, {
          style: {
            color: routeColor,
            weight: 4,
            opacity: 0.8
          }
        }).addTo(this.map)

        // Fit the map to show the entire route
        const group = L.featureGroup([startMarker, endMarker, this.routeLine])
        this.map.fitBounds(group.getBounds(), { padding: [20, 20] })

        // Store route coordinates for waypoint validation
        this.routeCoordinates = routeData.geometry.coordinates

        // Update popup with route information
        if (routeData.properties) {
          const distance = routeData.properties.segments?.[0]?.distance
          const duration = routeData.properties.segments?.[0]?.duration

          if (distance && duration) {
            const distanceKm = (distance / 1000).toFixed(1)
            const durationHours = (duration / 3600).toFixed(1)
            const avoidanceNote = this.avoidMotorwaysValue ?
              '<br><span style="color: #10B981; font-weight: bold;">🛣️ Avoiding highways & tolls</span>' : ''

            startMarker.bindPopup(`
              <strong>Start:</strong><br>
              ${this.startLocationValue}<br><br>
              <strong>Route:</strong><br>
              Distance: ${distanceKm} km<br>
              Duration: ${durationHours} hours${avoidanceNote}
            `)
          }
        }
      } else {
        // Handle routing failure based on highway avoidance setting
        if (this.avoidMotorwaysValue) {
          console.warn('Highway avoidance routing failed, cannot guarantee highway-free route')
          this.showHighwayAvoidanceError(startMarker, endMarker, [])
        } else {
          console.warn('Unable to get route data, falling back to straight line')
          this.drawStraightLine(startCoords, endCoords, startMarker, endMarker, false)
        }
      }
    } catch (error) {
      console.warn('Routing failed:', error)
      if (this.avoidMotorwaysValue) {
        console.warn('Highway avoidance routing failed, cannot guarantee highway-free route')
        this.showHighwayAvoidanceError(startMarker, endMarker, [])
      } else {
        console.warn('Falling back to straight line')
        this.drawStraightLine(startCoords, endCoords, startMarker, endMarker, false)
      }
    }

    // Open the start popup by default
    startMarker.openPopup()
  }

  setupMapClickListener() {
    this.map.on('click', (e) => {
      const { lat, lng } = e.latlng
      this.addWaypoint(lat, lng)
    })
  }

  addWaypoint(lat, lng) {
    this.waypointCounter++

    const waypoint = {
      id: this.waypointCounter,
      latitude: lat,
      longitude: lng,
      position: this.waypoints.length + 1
    }

    // Create waypoint marker
    const marker = L.marker([lat, lng], {
      icon: this.createWaypointIcon(waypoint.position)
    }).addTo(this.map)
      .bindPopup(`<strong>Waypoint ${waypoint.position}</strong><br>Click to remove`)

    // Add click handler to remove waypoint
    marker.on('click', (e) => {
      e.originalEvent.stopPropagation()
      this.removeWaypoint(waypoint.id)
    })

    waypoint.marker = marker
    this.waypoints.push(waypoint)

    this.updateWaypointsData()
    this.updateWaypointsList()
    this.updateRouteWithWaypoints()
  }

  removeWaypoint(waypointId) {
    const waypointIndex = this.waypoints.findIndex(w => w.id === waypointId)
    if (waypointIndex === -1) return

    const waypoint = this.waypoints[waypointIndex]

    // Remove marker from map
    this.map.removeLayer(waypoint.marker)

    // Remove from waypoints array
    this.waypoints.splice(waypointIndex, 1)

    // Reorder remaining waypoints
    this.waypoints.forEach((w, index) => {
      w.position = index + 1
      w.marker.setIcon(this.createWaypointIcon(w.position))
      w.marker.setPopupContent(`<strong>Waypoint ${w.position}</strong><br>Click to remove`)
    })

    this.updateWaypointsData()
    this.updateWaypointsList()
    this.updateRouteWithWaypoints()
  }

  updateWaypointsData() {
    const waypointsData = this.waypoints.map(w => ({
      latitude: w.latitude,
      longitude: w.longitude,
      position: w.position
    }))

    const waypointsField = document.getElementById('waypoints-data')
    if (waypointsField) {
      waypointsField.value = JSON.stringify(waypointsData)
    }
  }

  updateWaypointsList() {
    const waypointsList = document.getElementById('waypoints-list')
    if (!waypointsList) return

    if (this.waypoints.length === 0) {
      waypointsList.innerHTML = `
        <div class="text-gray-500 text-sm italic">
          No waypoints set. Click on the map to add waypoints.
        </div>
      `
    } else {
      waypointsList.innerHTML = this.waypoints.map(w => `
        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-md">
          <div class="flex items-center">
            <div class="w-6 h-6 bg-orange-500 text-white text-xs rounded-full flex items-center justify-center mr-3">
              ${w.position}
            </div>
            <div class="text-sm">
              <div class="font-medium text-gray-900">Waypoint ${w.position}</div>
              <div class="text-gray-600">${w.latitude.toFixed(6)}, ${w.longitude.toFixed(6)}</div>
            </div>
          </div>
          <button type="button" onclick="this.dispatchEvent(new CustomEvent('remove-waypoint', {detail: {id: ${w.id}}, bubbles: true}))"
                  class="text-red-600 hover:text-red-800 text-sm font-medium">
            Remove
          </button>
        </div>
      `).join('')
    }
  }

  async updateRouteWithWaypoints() {
    if (this.waypoints.length === 0) {
      // Show original route without waypoints
      return
    }

    try {
      // Create coordinates array: start -> waypoints (ordered) -> end
      const startCoords = await this.geocode(this.startLocationValue)
      const endCoords = await this.geocode(this.endLocationValue)

      if (!startCoords || !endCoords) return

      const orderedWaypoints = this.waypoints
        .sort((a, b) => a.position - b.position)
        .map(w => [w.latitude, w.longitude])

      const allCoords = [startCoords, ...orderedWaypoints, endCoords]

      // Get route with waypoints
      const routeWithWaypoints = await this.getRouteWithWaypoints(allCoords)

      if (routeWithWaypoints && routeWithWaypoints.geometry) {
        // Remove existing route line
        if (this.routeLine) {
          this.map.removeLayer(this.routeLine)
        }

        // Draw new route with waypoints
        // Use red color to show modified route (regardless of highway avoidance)
        this.routeLine = L.geoJSON(routeWithWaypoints.geometry, {
          style: {
            color: '#DC2626', // Red color to show modified route with waypoints
            weight: 4,
            opacity: 0.8
          }
        }).addTo(this.map)
      }
    } catch (error) {
      console.warn('Unable to update route with waypoints:', error)
    }
  }

  async getRouteWithWaypoints(coordinates) {
    try {
      // Use OSRM for routing with waypoints
      const coordsString = coordinates
        .map(coord => `${coord[1]},${coord[0]}`) // lon,lat format
        .join(';')

      const url = `https://router.project-osrm.org/route/v1/driving/${coordsString}?overview=full&geometries=geojson`

      const response = await fetch(url)

      if (!response.ok) {
        throw new Error(`Routing request failed: ${response.status}`)
      }

      const data = await response.json()

      if (data && data.routes && data.routes.length > 0) {
        const route = data.routes[0]
        return {
          geometry: route.geometry,
          properties: {
            segments: [{
              distance: route.distance,
              duration: route.duration
            }]
          }
        }
      }

      return null
    } catch (error) {
      console.error('Routing with waypoints error:', error)
      return null
    }
  }

  async getRoute(startCoords, endCoords) {
    // If avoid_motorways is enabled, use OpenRouteService with highway avoidance
    if (this.avoidMotorwaysValue) {
      return await this.getRouteOpenRouteService(startCoords, endCoords)
    } else {
      return await this.getRouteOSRM(startCoords, endCoords)
    }
  }

  async getRouteOpenRouteService(startCoords, endCoords) {
    try {
      const [startLat, startLon] = startCoords
      const [endLat, endLon] = endCoords

      console.log('Using Rails API proxy for OpenRouteService:')
      console.log('- Start coords:', [startLat, startLon])
      console.log('- End coords:', [endLat, endLon])

      // Use Rails API endpoint to avoid CORS issues
      const url = `/api/route_data?start_lat=${startLat}&start_lon=${startLon}&end_lat=${endLat}&end_lon=${endLon}&avoid_motorways=true`
      console.log('- API URL:', url)

      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      console.log('- Response status:', response.status)
      console.log('- Response ok:', response.ok)

      if (!response.ok) {
        const errorText = await response.text()
        console.error('Rails API error:', response.status, errorText)
        return null
      }

      const data = await response.json()
      console.log('- Response data structure:', {
        type: data?.type || 'N/A',
        hasGeometry: !!(data && data.geometry),
        hasProperties: !!(data && data.properties)
      })

      if (data && data.type === 'Feature' && data.geometry) {
        console.log('- SUCCESS: Got route data via Rails API')
        return data
      }

      console.warn('- No valid route feature in response')
      return null
    } catch (error) {
      console.error('Rails API routing error:', error)
      // Don't fall back to OSRM as it doesn't avoid highways
      return null
    }
  }

  async getRouteOSRM(startCoords, endCoords) {
    try {
      // Use Rails API endpoint for OSRM routing
      const [startLat, startLon] = startCoords
      const [endLat, endLon] = endCoords

      console.log('Using Rails API proxy for OSRM:')
      console.log('- Start coords:', [startLat, startLon])
      console.log('- End coords:', [endLat, endLon])

      const url = `/api/route_data?start_lat=${startLat}&start_lon=${startLon}&end_lat=${endLat}&end_lon=${endLon}&avoid_motorways=false`
      console.log('- API URL:', url)

      const response = await fetch(url, {
        method: 'GET',
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest'
        }
      })

      console.log('- Response status:', response.status)
      console.log('- Response ok:', response.ok)

      if (!response.ok) {
        const errorText = await response.text()
        console.error('Rails API error:', response.status, errorText)
        return null
      }

      const data = await response.json()
      console.log('- Response data structure:', {
        type: data?.type || 'N/A',
        hasGeometry: !!(data && data.geometry),
        hasProperties: !!(data && data.properties)
      })

      if (data && data.type === 'Feature' && data.geometry) {
        console.log('- SUCCESS: Got OSRM route data via Rails API')
        return data
      }

      console.warn('- No valid route feature in response')
      return null
    } catch (error) {
      console.error('Rails API OSRM routing error:', error)
      return null
    }
  }

  async getRouteAlternative(startCoords, endCoords) {
    try {
      // Alternative: Use OSRM (Open Source Routing Machine) as fallback
      const [startLat, startLon] = startCoords
      const [endLat, endLon] = endCoords

      const url = `https://router.project-osrm.org/route/v1/driving/${startLon},${startLat};${endLon},${endLat}?overview=full&geometries=geojson`

      const response = await fetch(url)

      if (!response.ok) {
        throw new Error(`Alternative routing request failed: ${response.status}`)
      }

      const data = await response.json()

      if (data && data.routes && data.routes.length > 0) {
        const route = data.routes[0]
        return {
          geometry: route.geometry,
          properties: {
            segments: [{
              distance: route.distance,
              duration: route.duration
            }]
          }
        }
      }

      return null
    } catch (error) {
      console.error('Alternative routing error:', error)
      return null
    }
  }

  drawStraightLine(startCoords, endCoords, startMarker, endMarker, isHighwayAvoidanceFallback = false) {
    // Fallback: Draw a straight line between the points
    const routeLine = L.polyline([startCoords, endCoords], {
      color: isHighwayAvoidanceFallback ? '#10B981' : '#DC2626', // Green for highway avoidance fallback, red for general fallback
      weight: 4,
      opacity: 0.8,
      dashArray: '10, 5' // Dashed line to indicate it's approximate
    }).addTo(this.map)

    // Fit the map to show both points
    const group = L.featureGroup([startMarker, endMarker, routeLine])
    this.map.fitBounds(group.getBounds(), { padding: [20, 20] })

    // Add a note about the straight line with context-specific message
    const message = isHighwayAvoidanceFallback ?
      `<strong>Start:</strong><br>
       ${this.startLocationValue}<br><br>
       <em style="color: #10B981;">
         🛣️ Highway avoidance requested<br>
         Showing straight line distance<br>
         (highway-free routing unavailable)
       </em>` :
      `<strong>Start:</strong><br>
       ${this.startLocationValue}<br><br>
       <em style="color: #DC2626;">
         Note: Showing straight line distance<br>
         (routing service unavailable)
       </em>`

    startMarker.bindPopup(message)

    // Store a simplified route for waypoint validation
    this.routeCoordinates = [[startCoords[1], startCoords[0]], [endCoords[1], endCoords[0]]]
  }

  showHighwayAvoidanceError(startMarker, endMarker, waypointMarkers = []) {
    // Show markers without any route lines
    const allMarkers = [startMarker, endMarker, ...waypointMarkers]
    const group = L.featureGroup(allMarkers)
    this.map.fitBounds(group.getBounds(), { padding: [20, 20] })

    // Add error message to start popup
    startMarker.bindPopup(`
      <strong>Start:</strong><br>
      ${this.startLocationValue}<br><br>
      <div style="color: #DC2626;">
        <strong>⚠️ Highway Avoidance Error</strong><br>
        Cannot calculate highway-free route.<br>
        Please check your API configuration.
      </div>
    `)

    // Open the popup to show the error
    startMarker.openPopup()
  }

  async geocode(location) {
    try {
      // Use Nominatim (OpenStreetMap's geocoding service)
      const response = await fetch(
        `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(location)}&limit=1`
      )

      if (!response.ok) {
        throw new Error('Geocoding request failed')
      }

      const data = await response.json()

      if (data && data.length > 0) {
        return [parseFloat(data[0].lat), parseFloat(data[0].lon)]
      }

      return null
    } catch (error) {
      console.error('Geocoding error:', error)
      return null
    }
  }

  createStartIcon() {
    return L.divIcon({
      className: 'custom-div-icon start-icon',
      html: `
        <div style="background-color: #10B981; color: white; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3); font-size: 12px; font-weight: bold;">
          S
        </div>
      `,
      iconSize: [30, 30],
      iconAnchor: [15, 15]
    })
  }

  createEndIcon() {
    return L.divIcon({
      className: 'custom-div-icon end-icon',
      html: `
        <div style="background-color: #EF4444; color: white; width: 30px; height: 30px; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3); font-size: 12px; font-weight: bold;">
          E
        </div>
      `,
      iconSize: [30, 30],
      iconAnchor: [15, 15]
    })
  }

  createWaypointIcon(position) {
    return L.divIcon({
      className: 'custom-div-icon waypoint-icon',
      html: `
        <div style="background-color: #F97316; color: white; width: 25px; height: 25px; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3); font-size: 10px; font-weight: bold; cursor: pointer;">
          ${position}
        </div>
      `,
      iconSize: [25, 25],
      iconAnchor: [12.5, 12.5]
    })
  }

  showError(message) {
    const errorDiv = document.createElement('div')
    errorDiv.className = 'absolute inset-0 bg-red-50 flex items-center justify-center'
    errorDiv.innerHTML = `
      <div class="text-center p-4">
        <div class="text-red-600 mb-2">
          <svg class="h-8 w-8 mx-auto" fill="currentColor" viewBox="0 0 20 20">
            <path fill-rule="evenodd" d="M18 10a8 8 0 11-16 0 8 8 0 0116 0zm-7 4a1 1 0 11-2 0 1 1 0 012 0zm-1-9a1 1 0 00-1 1v4a1 1 0 102 0V6a1 1 0 00-1-1z" clip-rule="evenodd" />
          </svg>
        </div>
        <div class="text-sm text-red-700">${message}</div>
      </div>
    `
    this.element.appendChild(errorDiv)
  }
}

// Handle remove waypoint events
document.addEventListener('remove-waypoint', (event) => {
  // Find the controller through the Stimulus application
  const mapElement = document.querySelector('[data-controller~="waypoints-map"]')
  if (mapElement) {
    const application = window.Stimulus || window.Application
    if (application) {
      const controller = application.getControllerForElementAndIdentifier(mapElement, 'waypoints-map')
      if (controller) {
        controller.removeWaypoint(event.detail.id)
      }
    }
  }
})