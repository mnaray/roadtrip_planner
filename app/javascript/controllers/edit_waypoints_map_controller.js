import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="edit-waypoints-map"
export default class extends Controller {
  static values = {
    startLocation: String,
    endLocation: String,
    existingWaypoints: Array,
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

    // Performance optimization: Geocoding cache
    this.geocodeCache = new Map()

    // Performance optimization: Debounced route updates
    this.routeUpdateTimeout = null
    this.ROUTE_UPDATE_DEBOUNCE = 300 // ms

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
      this.bindNameInputEvents()
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
          position: waypointData.position,
          name: waypointData.name || `Waypoint ${waypointData.position}`
        }

        // Create draggable waypoint marker
        const marker = L.marker([waypoint.latitude, waypoint.longitude], {
          icon: this.createWaypointIcon(waypoint.position),
          draggable: true
        }).addTo(this.map)
          .bindPopup(`<strong>${waypoint.name}</strong><br>Drag to reposition, click to remove`)

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
      position: this.waypoints.length + 1,
      name: `Waypoint ${this.waypoints.length + 1}`
    }

    // Create draggable waypoint marker
    const marker = L.marker([lat, lng], {
      icon: this.createWaypointIcon(waypoint.position),
      draggable: true
    }).addTo(this.map)
      .bindPopup(`<strong>${waypoint.name}</strong><br>Drag to reposition, click to remove`)

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
      // Update name if it was just the default positional name
      if (w.name.match(/^Waypoint \d+$/)) {
        w.name = `Waypoint ${w.position}`
      }
      w.marker.setIcon(this.createWaypointIcon(w.position))
      w.marker.setPopupContent(`<strong>${w.name}</strong><br>Drag to reposition, click to remove`)
    })

    this.updateWaypointsData()
    this.updateWaypointsList()
    this.updateRouteWithWaypoints()
  }

  updateWaypointsData() {
    const waypointsData = this.waypoints.map(w => ({
      latitude: w.latitude,
      longitude: w.longitude,
      position: w.position,
      name: w.name
    }))

    const waypointsField = document.getElementById('waypoints-data')
    if (waypointsField) {
      waypointsField.value = JSON.stringify(waypointsData)
    }
  }

  // Performance optimization: Targeted DOM updates instead of full rebuild
  updateWaypointsList() {
    const waypointsList = document.getElementById('waypoints-list')
    if (!waypointsList) return

    // Find the sortable container (skip the instruction text)
    const sortableContainer = waypointsList.querySelector('[data-controller="sortable-waypoints"]') || waypointsList

    if (this.waypoints.length === 0) {
      this.showEmptyWaypointsMessage(sortableContainer)
      return
    }

    // Get existing waypoint elements
    const existingElements = Array.from(sortableContainer.querySelectorAll('[data-waypoint-id]'))
    const existingIds = new Set(existingElements.map(el => parseInt(el.dataset.waypointId)))

    // Remove empty message if it exists
    const emptyMessage = sortableContainer.querySelector('.text-gray-500')
    if (emptyMessage) {
      emptyMessage.remove()
    }

    // Update existing elements and create new ones
    this.waypoints.forEach((waypoint, index) => {
      let element = existingElements.find(el => parseInt(el.dataset.waypointId) === waypoint.id)

      if (element) {
        // Update existing element
        this.updateWaypointElement(element, waypoint)
        // Ensure correct order
        const targetPosition = index
        const currentPosition = Array.from(sortableContainer.children).indexOf(element)
        if (currentPosition !== targetPosition) {
          const referenceElement = sortableContainer.children[targetPosition]
          if (referenceElement) {
            sortableContainer.insertBefore(element, referenceElement)
          } else {
            sortableContainer.appendChild(element)
          }
        }
      } else {
        // Create new element
        element = this.createWaypointElement(waypoint)
        // Insert at correct position
        const referenceElement = sortableContainer.children[index]
        if (referenceElement) {
          sortableContainer.insertBefore(element, referenceElement)
        } else {
          sortableContainer.appendChild(element)
        }
      }

      existingIds.delete(waypoint.id)
    })

    // Remove elements for waypoints that no longer exist
    existingIds.forEach(id => {
      const element = sortableContainer.querySelector(`[data-waypoint-id="${id}"]`)
      if (element) {
        element.remove()
      }
    })

    // Only refresh sortable controller if DOM structure changed significantly
    if (existingIds.size > 0 || this.waypoints.some(w => !existingElements.find(el => parseInt(el.dataset.waypointId) === w.id))) {
      const sortableController = this.application.getControllerForElementAndIdentifier(sortableContainer, 'sortable-waypoints')
      if (sortableController && sortableController.makeItemsSortable) {
        setTimeout(() => {
          sortableController.makeItemsSortable()
          // Rebind name input events after DOM updates
          this.bindNameInputEvents()
        }, 10)
      }
    }
  }

  showEmptyWaypointsMessage(container) {
    if (container.querySelector('.text-gray-500')) return // Already showing

    container.innerHTML = `
      <div class="text-gray-500 text-sm italic">
        No waypoints set. Click on the map to add waypoints.
      </div>
    `
  }

  updateWaypointElement(element, waypoint) {
    // Update data attributes
    element.dataset.position = waypoint.position.toString()
    element.dataset.latitude = waypoint.latitude.toString()
    element.dataset.longitude = waypoint.longitude.toString()
    element.dataset.name = waypoint.name

    // Update position badge
    const badge = element.querySelector('.waypoint-position-badge')
    if (badge) {
      badge.textContent = waypoint.position.toString()
    }

    // Update name input
    const nameInput = element.querySelector('.waypoint-name-input')
    if (nameInput) {
      nameInput.value = waypoint.name
    }

    // Update coordinates
    const coords = element.querySelector('.waypoint-coordinates')
    if (coords) {
      coords.textContent = `${waypoint.latitude.toFixed(6)}, ${waypoint.longitude.toFixed(6)}`
    }
  }

  createWaypointElement(waypoint) {
    const element = document.createElement('div')
    element.className = 'flex items-center justify-between p-3 bg-gray-50 rounded-md hover:bg-gray-100 transition-colors'
    element.setAttribute('data-sortable-waypoints-target', 'item')
    element.setAttribute('data-waypoint-id', waypoint.id.toString())
    element.setAttribute('data-position', waypoint.position.toString())
    element.setAttribute('data-latitude', waypoint.latitude.toString())
    element.setAttribute('data-longitude', waypoint.longitude.toString())
    element.setAttribute('data-name', waypoint.name)
    element.draggable = true

    element.innerHTML = `
      <div class="flex items-center flex-1">
        <div class="mr-3 text-gray-400 hover:text-gray-600 cursor-move">
          <svg class="w-4 h-4" viewBox="0 0 20 20">
            <path d="M10 6h4v1H10V6zM10 8h4v1H10V8zM10 10h4v1H10v-1zM8 6H6v1h2V6zM8 8H6v1h2V8zM8 10H6v1h2v-1z" fill="currentColor"/>
          </svg>
        </div>
        <div class="w-6 h-6 bg-orange-500 text-white text-xs rounded-full flex items-center justify-center mr-3 waypoint-position-badge">
          ${waypoint.position}
        </div>
        <div class="flex-1">
          <div class="flex items-center mb-1">
            <input type="text"
                   value="${waypoint.name}"
                   class="waypoint-name-input text-sm font-medium text-gray-900 bg-transparent border-none outline-none focus:bg-white focus:border focus:border-blue-300 focus:rounded px-2 py-1 -ml-2"
                   placeholder="Waypoint name"
                   maxlength="100">
          </div>
          <div class="text-xs text-gray-600 waypoint-coordinates">${waypoint.latitude.toFixed(6)}, ${waypoint.longitude.toFixed(6)}</div>
        </div>
      </div>
    `

    // Add event listener for name changes
    const nameInput = element.querySelector('.waypoint-name-input')
    this.addNameInputListeners(nameInput)

    return element
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
      marker.setPopupContent(`<strong>${waypoint.name}</strong><br>Drag to reposition, click to remove`)

      // Update data and refresh route
      this.updateWaypointsData()
      this.updateWaypointsList()
      // Use debounced route update for drag operations
      this.debouncedUpdateRoute()
    })
  }

  // Performance optimization: Debounced route updates
  debouncedUpdateRoute() {
    // Clear existing timeout
    if (this.routeUpdateTimeout) {
      clearTimeout(this.routeUpdateTimeout)
    }

    // Set new timeout for debounced update
    this.routeUpdateTimeout = setTimeout(() => {
      this.updateRouteWithWaypoints()
    }, this.ROUTE_UPDATE_DEBOUNCE)
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
        // Use different colors: Green for highway-avoiding routes, Red for normal routes with waypoints
        const routeColor = this.avoidMotorwaysValue ? '#10B981' : '#DC2626' // Green for highway-free, red for normal with waypoints
        this.routeLine = L.geoJSON(routeWithWaypoints.geometry, {
          style: {
            color: routeColor,
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
    // If avoid_motorways is enabled, use OpenRouteService
    if (this.avoidMotorwaysValue) {
      return await this.getRouteWithWaypointsOpenRouteService(coordinates)
    } else {
      return await this.getRouteWithWaypointsOSRM(coordinates)
    }
  }

  async getRouteWithWaypointsOpenRouteService(coordinates) {
    try {
      // Use Rails API proxy for OpenRouteService waypoint routing with highway avoidance
      const coordinatesLonLat = coordinates.map(coord => [coord[1], coord[0]]) // Convert to [lon, lat]

      console.log('Using Rails API proxy for OpenRouteService waypoint routing (edit waypoints):')
      console.log('- Coordinates:', coordinatesLonLat)

      const response = await fetch('/api/route_data_with_waypoints', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
        },
        body: JSON.stringify({
          coordinates: coordinatesLonLat,
          avoid_motorways: true
        })
      })

      console.log('- Response status:', response.status)
      console.log('- Response ok:', response.ok)

      if (!response.ok) {
        const errorText = await response.text()
        console.error('Rails API waypoint routing error:', response.status, errorText)
        return null
      }

      const data = await response.json()
      console.log('- Response data structure:', {
        type: data?.type || 'N/A',
        hasGeometry: !!(data && data.geometry),
        hasProperties: !!(data && data.properties)
      })

      if (data && data.type === 'Feature' && data.geometry) {
        console.log('- SUCCESS: Got waypoint route data via Rails API (edit waypoints)')
        return data
      }

      console.warn('- No valid waypoint route feature in response')
      return null
    } catch (error) {
      console.error('Rails API waypoint routing error:', error)
      // Don't fall back to OSRM as it doesn't avoid highways
      return null
    }
  }

  async getRouteWithWaypointsOSRM(coordinates) {
    try {
      // Use Rails API proxy for OSRM waypoint routing
      const coordinatesLonLat = coordinates.map(coord => [coord[1], coord[0]]) // Convert to [lon, lat]

      console.log('Using Rails API proxy for OSRM waypoint routing (edit waypoints):')
      console.log('- Coordinates:', coordinatesLonLat)

      const response = await fetch('/api/route_data_with_waypoints', {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'X-CSRF-Token': document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || ''
        },
        body: JSON.stringify({
          coordinates: coordinatesLonLat,
          avoid_motorways: false
        })
      })

      console.log('- Response status:', response.status)
      console.log('- Response ok:', response.ok)

      if (!response.ok) {
        const errorText = await response.text()
        console.error('Rails API OSRM waypoint routing error:', response.status, errorText)
        return null
      }

      const data = await response.json()
      console.log('- Response data structure:', {
        type: data?.type || 'N/A',
        hasGeometry: !!(data && data.geometry),
        hasProperties: !!(data && data.properties)
      })

      if (data && data.type === 'Feature' && data.geometry) {
        console.log('- SUCCESS: Got OSRM waypoint route data via Rails API (edit waypoints)')
        return data
      }

      console.warn('- No valid OSRM waypoint route feature in response')
      return null
    } catch (error) {
      console.error('Rails API OSRM waypoint routing error:', error)
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

      console.log('Using Rails API proxy for OpenRouteService (edit waypoints):')
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
        console.log('- SUCCESS: Got route data via Rails API (edit waypoints)')
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

      console.log('Using Rails API proxy for OSRM (edit waypoints):')
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
        console.log('- SUCCESS: Got OSRM route data via Rails API (edit waypoints)')
        return data
      }

      console.warn('- No valid route feature in response')
      return null
    } catch (error) {
      console.error('Rails API OSRM routing error:', error)
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
    // Performance optimization: Check cache first
    if (this.geocodeCache.has(location)) {
      return this.geocodeCache.get(location)
    }

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
        const coordinates = [parseFloat(data[0].lat), parseFloat(data[0].lon)]
        // Cache the result
        this.geocodeCache.set(location, coordinates)
        return coordinates
      }

      // Cache null results to avoid repeated failed requests
      this.geocodeCache.set(location, null)
      return null
    } catch (error) {
      console.error('Geocoding error:', error)
      // Cache null results for failed requests
      this.geocodeCache.set(location, null)
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
    if (waypointItems.length === 0) return

    // Create a new ordered array based on the current DOM order
    const reorderedWaypoints = []

    waypointItems.forEach((item, index) => {
      const waypointId = parseInt(item.dataset.waypointId)
      const newPosition = index + 1

      // Find the existing waypoint by ID
      const existingWaypoint = this.waypoints.find(w => w.id === waypointId)
      if (existingWaypoint) {
        // Get current name from DOM element or use existing name
        const currentName = item.dataset.name || existingWaypoint.name

        // Update the position and add to reordered array
        const updatedWaypoint = {
          ...existingWaypoint,
          position: newPosition,
          name: currentName
        }
        reorderedWaypoints.push(updatedWaypoint)

        // Update the marker icon and popup
        if (existingWaypoint.marker) {
          existingWaypoint.marker.setIcon(this.createWaypointIcon(newPosition))
          existingWaypoint.marker.setPopupContent(`<strong>${currentName}</strong><br>Drag to reposition, click to remove`)
        }
      }
    })

    // Replace the waypoints array with the reordered one
    this.waypoints = reorderedWaypoints

    // Update the hidden form field and refresh the route
    this.updateWaypointsData()
    // Use debounced route update for reordering operations
    this.debouncedUpdateRoute()
  }

  bindNameInputEvents() {
    // Bind events to existing waypoint name inputs
    const nameInputs = document.querySelectorAll('.waypoint-name-input')
    nameInputs.forEach(input => {
      this.addNameInputListeners(input)
    })
  }

  addNameInputListeners(input) {
    const waypointElement = input.closest('[data-waypoint-id]')
    if (!waypointElement) return

    const waypointId = parseInt(waypointElement.dataset.waypointId)
    const waypoint = this.waypoints.find(w => w.id === waypointId)

    if (!waypoint) return

    // Remove existing listeners to prevent duplicates
    input.removeEventListener('input', this.handleNameInput)
    input.removeEventListener('blur', this.handleNameBlur)

    // Create bound handlers
    const handleInput = (e) => {
      waypoint.name = e.target.value || `Waypoint ${waypoint.position}`
      waypointElement.setAttribute('data-name', waypoint.name)
      this.updateWaypointsData()

      // Update map marker popup if it exists
      if (waypoint.marker) {
        waypoint.marker.setPopupContent(`<strong>${waypoint.name}</strong><br>Drag to reposition, click to remove`)
      }
    }

    const handleBlur = (e) => {
      if (!e.target.value.trim()) {
        e.target.value = `Waypoint ${waypoint.position}`
        waypoint.name = e.target.value
        waypointElement.setAttribute('data-name', waypoint.name)
        this.updateWaypointsData()

        // Update map marker popup
        if (waypoint.marker) {
          waypoint.marker.setPopupContent(`<strong>${waypoint.name}</strong><br>Drag to reposition, click to remove`)
        }
      }
    }

    // Add event listeners
    input.addEventListener('input', handleInput)
    input.addEventListener('blur', handleBlur)

    // Store handlers for cleanup
    input.handleNameInput = handleInput
    input.handleNameBlur = handleBlur
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