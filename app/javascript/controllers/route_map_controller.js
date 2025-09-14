import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="route-map"
export default class extends Controller {
  static values = {
    startLocation: String,
    endLocation: String,
    waypoints: Array
  }

  connect() {
    // Check if Leaflet is available
    if (typeof L === 'undefined') {
      console.error('Leaflet (L) is not available. Make sure leaflet.js is loaded.')
      this.showError('Map library is not available. Please refresh the page.')
      return
    }
    
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

    // Add waypoint markers if they exist
    this.waypointMarkers = []
    if (this.waypointsValue && this.waypointsValue.length > 0) {
      this.waypointsValue.forEach((waypoint, index) => {
        const waypointMarker = L.marker([waypoint.latitude, waypoint.longitude], {
          icon: this.createWaypointIcon(waypoint.position)
        }).addTo(this.map)
          .bindPopup(`<strong>Waypoint ${waypoint.position}</strong><br>Lat: ${waypoint.latitude.toFixed(6)}<br>Lng: ${waypoint.longitude.toFixed(6)}`)

        this.waypointMarkers.push(waypointMarker)
      })
    }

    // Get the actual driving route (with waypoints if they exist)
    try {
      let routeData
      if (this.waypointsValue && this.waypointsValue.length > 0) {
        // Create coordinates array: start -> waypoints (ordered) -> end
        const orderedWaypoints = this.waypointsValue
          .sort((a, b) => a.position - b.position)
          .map(w => [w.latitude, w.longitude])

        const allCoords = [startCoords, ...orderedWaypoints, endCoords]
        routeData = await this.getRouteWithWaypoints(allCoords)
      } else {
        routeData = await this.getRoute(startCoords, endCoords)
      }

      if (routeData && routeData.geometry) {
        // Draw the actual route following roads
        const routeLine = L.geoJSON(routeData.geometry, {
          style: {
            color: '#3B82F6',
            weight: 4,
            opacity: 0.8
          }
        }).addTo(this.map)

        // Fit the map to show the entire route including waypoints
        const allMarkers = [startMarker, endMarker, ...this.waypointMarkers]
        const group = L.featureGroup([...allMarkers, routeLine])
        this.map.fitBounds(group.getBounds(), { padding: [20, 20] })

        // Update popup with route information
        if (routeData.properties) {
          const distance = routeData.properties.segments?.[0]?.distance
          const duration = routeData.properties.segments?.[0]?.duration

          if (distance && duration) {
            const distanceKm = (distance / 1000).toFixed(1)
            const durationHours = (duration / 3600).toFixed(1)
            
            startMarker.bindPopup(`
              <strong>Start:</strong><br>
              ${this.startLocationValue}<br><br>
              <strong>Route:</strong><br>
              Distance: ${distanceKm} km<br>
              Duration: ${durationHours} hours
            `)
          }
        }
      } else {
        // Fallback to straight line if routing fails
        console.warn('Unable to get route data, falling back to straight line. Route data:', routeData)
        this.drawStraightLine(startCoords, endCoords, startMarker, endMarker, this.waypointMarkers)
      }
    } catch (error) {
      console.warn('Routing failed, falling back to straight line:', error)
      this.drawStraightLine(startCoords, endCoords, startMarker, endMarker, this.waypointMarkers)
    }

    // Open the start popup by default
    startMarker.openPopup()
  }

  async getRoute(startCoords, endCoords) {
    try {
      // Use OpenRouteService for routing (free, no API key required for basic usage)
      const [startLat, startLon] = startCoords
      const [endLat, endLon] = endCoords
      
      const url = `https://api.openrouteservice.org/v2/directions/driving-car?start=${startLon},${startLat}&end=${endLon},${endLat}`
      
      const response = await fetch(url, {
        headers: {
          'Accept': 'application/json, application/geo+json, application/gpx+xml, img/png; charset=utf-8'
        }
      })
      
      if (!response.ok) {
        throw new Error(`Routing request failed: ${response.status}`)
      }

      const data = await response.json()
      
      if (data && data.features && data.features.length > 0) {
        return data.features[0]
      }
      
      return null
    } catch (error) {
      console.error('Routing error:', error)
      // Try alternative routing service as fallback
      return await this.getRouteAlternative(startCoords, endCoords)
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

  drawStraightLine(startCoords, endCoords, startMarker, endMarker, waypointMarkers = []) {
    // Fallback: Draw a straight line between the points
    const routeLine = L.polyline([startCoords, endCoords], {
      color: '#DC2626', // Red color to indicate it's not a real route
      weight: 4,
      opacity: 0.8,
      dashArray: '10, 5' // Dashed line to indicate it's approximate
    }).addTo(this.map)

    // Fit the map to show both points and waypoints
    const allMarkers = [startMarker, endMarker, ...waypointMarkers]
    const group = L.featureGroup([...allMarkers, routeLine])
    this.map.fitBounds(group.getBounds(), { padding: [20, 20] })

    // Add a note about the straight line
    startMarker.bindPopup(`
      <strong>Start:</strong><br>
      ${this.startLocationValue}<br><br>
      <em style="color: #DC2626;">
        Note: Showing straight line distance<br>
        (routing service unavailable)
      </em>
    `)
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
        <div style="background-color: #F97316; color: white; width: 25px; height: 25px; border-radius: 50%; display: flex; align-items: center; justify-content: center; border: 2px solid white; box-shadow: 0 2px 4px rgba(0,0,0,0.3); font-size: 10px; font-weight: bold;">
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