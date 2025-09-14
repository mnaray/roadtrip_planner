import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="edit-waypoints-map"
export default class extends Controller {
  static values = {
    startLocation: String,
    endLocation: String,
    existingWaypoints: Array
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
      this.loadExistingWaypoints()
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

  loadExistingWaypoints() {
    // Load existing waypoints from the route
    if (this.existingWaypointsValue && this.existingWaypointsValue.length > 0) {
      this.existingWaypointsValue.forEach(waypointData => {
        this.waypointCounter = Math.max(this.waypointCounter, waypointData.id || 0)

        const waypoint = {
          id: waypointData.id || ++this.waypointCounter,
          latitude: waypointData.latitude,
          longitude: waypointData.longitude,
          position: waypointData.position
        }

        // Create draggable waypoint marker
        const marker = L.marker([waypoint.latitude, waypoint.longitude], {
          icon: this.createWaypointIcon(waypoint.position),
          draggable: true
        }).addTo(this.map)
          .bindPopup(`<strong>Waypoint ${waypoint.position}</strong><br>Drag to reposition, click to remove`)

        // Add click handler to remove waypoint
        marker.on('click', (e) => {
          e.originalEvent.stopPropagation()
          this.removeWaypoint(waypoint.id)
        })

        // Add drag handlers for repositioning
        this.addDragHandlers(marker, waypoint)

        waypoint.marker = marker
        this.waypoints.push(waypoint)
      })

      this.updateWaypointsData()
      this.updateWaypointsList()
      this.updateRouteWithWaypoints()
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
        this.routeLine = L.geoJSON(routeData.geometry, {
          style: {
            color: '#3B82F6',
            weight: 4,
            opacity: 0.8
          }
        }).addTo(this.map)

        // Fit the map to show the entire route
        const group = L.featureGroup([startMarker, endMarker, this.routeLine])
        this.map.fitBounds(group.getBounds(), { padding: [20, 20] })

        // Store route coordinates for waypoint validation
        this.routeCoordinates = routeData.geometry.coordinates
      } else {
        // Fallback to straight line if routing fails
        console.warn('Unable to get route, falling back to straight line')
        this.drawStraightLine(startCoords, endCoords, startMarker, endMarker)
      }
    } catch (error) {
      console.warn('Routing failed, falling back to straight line:', error)
      this.drawStraightLine(startCoords, endCoords, startMarker, endMarker)
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

    // Create draggable waypoint marker
    const marker = L.marker([lat, lng], {
      icon: this.createWaypointIcon(waypoint.position),
      draggable: true
    }).addTo(this.map)
      .bindPopup(`<strong>Waypoint ${waypoint.position}</strong><br>Drag to reposition, click to remove`)

    // Add click handler to remove waypoint
    marker.on('click', (e) => {
      e.originalEvent.stopPropagation()
      this.removeWaypoint(waypoint.id)
    })

    // Add drag handlers for repositioning
    this.addDragHandlers(marker, waypoint)

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
      w.marker.setPopupContent(`<strong>Waypoint ${w.position}</strong><br>Drag to reposition, click to remove`)
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

    // Find the sortable container (skip the instruction text)
    const sortableContainer = waypointsList.querySelector('[data-controller="sortable-waypoints"]') || waypointsList

    if (this.waypoints.length === 0) {
      sortableContainer.innerHTML = `
        <div class="text-gray-500 text-sm italic">
          No waypoints set. Click on the map to add waypoints.
        </div>
      `
    } else {
      sortableContainer.innerHTML = this.waypoints.map(w => `
        <div class="flex items-center justify-between p-3 bg-gray-50 rounded-md cursor-move hover:bg-gray-100 transition-colors select-none"
             data-sortable-waypoints-target="item"
             data-waypoint-id="${w.id}"
             data-position="${w.position}"
             data-latitude="${w.latitude}"
             data-longitude="${w.longitude}">
          <div class="flex items-center">
            <div class="mr-3 text-gray-400 hover:text-gray-600">
              <svg class="w-4 h-4" viewBox="0 0 20 20">
                <path d="M10 6h4v1H10V6zM10 8h4v1H10V8zM10 10h4v1H10v-1zM8 6H6v1h2V6zM8 8H6v1h2V8zM8 10H6v1h2v-1z" fill="currentColor"/>
              </svg>
            </div>
            <div class="w-6 h-6 bg-orange-500 text-white text-xs rounded-full flex items-center justify-center mr-3 waypoint-position-badge">
              ${w.position}
            </div>
            <div class="text-sm">
              <div class="font-medium text-gray-900 waypoint-position-text">Waypoint ${w.position}</div>
              <div class="text-gray-600">${w.latitude.toFixed(6)}, ${w.longitude.toFixed(6)}</div>
            </div>
          </div>
        </div>
      `).join('')

      // Refresh sortable drag listeners after updating the DOM
      const sortableController = this.application.getControllerForElementAndIdentifier(sortableContainer, 'sortable-waypoints')
      if (sortableController && sortableController.refreshDragListeners) {
        sortableController.refreshDragListeners()
      }
    }
  }

  addDragHandlers(marker, waypoint) {
    // Add visual feedback on drag start
    marker.on('dragstart', () => {
      marker.setOpacity(0.5)
    })

    // Update position during drag
    marker.on('drag', (e) => {
      const { lat, lng } = e.target.getLatLng()
      waypoint.latitude = lat
      waypoint.longitude = lng
    })

    // Handle drag end
    marker.on('dragend', () => {
      marker.setOpacity(1.0)

      // Update the waypoint coordinates
      const { lat, lng } = marker.getLatLng()
      waypoint.latitude = lat
      waypoint.longitude = lng

      // Update popup content
      marker.setPopupContent(`<strong>Waypoint ${waypoint.position}</strong><br>Drag to reposition, click to remove`)

      // Update data and refresh route
      this.updateWaypointsData()
      this.updateWaypointsList()
      this.updateRouteWithWaypoints()
    })
  }

  async updateRouteWithWaypoints() {
    if (this.waypoints.length === 0 && (!this.existingWaypointsValue || this.existingWaypointsValue.length === 0)) {
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
        this.routeLine = L.geoJSON(routeWithWaypoints.geometry, {
          style: {
            color: '#DC2626', // Red color to show modified route
            weight: 4,
            opacity: 0.8
          }
        }).addTo(this.map)
      }
    } catch (error) {
      console.warn('Unable to update route with waypoints:', error)
    }
  }

  // Copy routing methods from waypoints_map_controller.js
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
    try {
      // Use OSRM for routing
      const [startLat, startLon] = startCoords
      const [endLat, endLon] = endCoords

      const url = `https://router.project-osrm.org/route/v1/driving/${startLon},${startLat};${endLon},${endLat}?overview=full&geometries=geojson`

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
      console.error('Routing error:', error)
      return null
    }
  }

  drawStraightLine(startCoords, endCoords, startMarker, endMarker) {
    // Fallback: Draw a straight line between the points
    this.routeLine = L.polyline([startCoords, endCoords], {
      color: '#DC2626', // Red color to indicate it's not a real route
      weight: 4,
      opacity: 0.8,
      dashArray: '10, 5' // Dashed line to indicate it's approximate
    }).addTo(this.map)

    // Fit the map to show both points
    const group = L.featureGroup([startMarker, endMarker, this.routeLine])
    this.map.fitBounds(group.getBounds(), { padding: [20, 20] })

    // Store a simplified route for waypoint validation
    this.routeCoordinates = [[startCoords[1], startCoords[0]], [endCoords[1], endCoords[0]]]
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

  // Method called by sortable waypoints controller to update waypoint positions
  updateWaypointPositionsFromList() {
    const waypointItems = document.querySelectorAll('[data-sortable-waypoints-target="item"]')
    const newPositions = []

    waypointItems.forEach((item, index) => {
      const waypointId = parseInt(item.dataset.waypointId)
      const latitude = parseFloat(item.dataset.latitude)
      const longitude = parseFloat(item.dataset.longitude)
      const newPosition = index + 1

      newPositions.push({
        id: waypointId,
        latitude: latitude,
        longitude: longitude,
        position: newPosition
      })
    })

    // Update internal waypoints array with new positions
    this.waypoints = newPositions.map(np => {
      const existingWaypoint = this.waypoints.find(w => w.id === np.id)
      if (!existingWaypoint) {
        return np // Use the new position data if we can't find existing
      }
      return {
        ...existingWaypoint,
        position: np.position
      }
    })

    // Update map markers with new positions
    this.waypoints.forEach(waypoint => {
      if (waypoint.marker) {
        waypoint.marker.setIcon(this.createWaypointIcon(waypoint.position))
        waypoint.marker.setPopupContent(`<strong>Waypoint ${waypoint.position}</strong><br>Drag to reposition, click to remove`)
      }
    })

    // Update data and refresh route
    this.updateWaypointsData()
    this.updateRouteWithWaypoints()
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