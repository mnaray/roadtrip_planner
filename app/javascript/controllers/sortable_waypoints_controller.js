import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sortable-waypoints"
export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.draggedElement = null
    this.placeholder = null
    this.attachDragListeners()
  }

  disconnect() {
    this.removeDragListeners()
  }

  attachDragListeners() {
    this.itemTargets.forEach(item => {
      item.draggable = true
      item.addEventListener('dragstart', this.dragStart.bind(this))
      item.addEventListener('dragover', this.dragOver.bind(this))
      item.addEventListener('dragenter', this.dragEnter.bind(this))
      item.addEventListener('dragleave', this.dragLeave.bind(this))
      item.addEventListener('drop', this.drop.bind(this))
      item.addEventListener('dragend', this.dragEnd.bind(this))
    })
  }

  removeDragListeners() {
    this.itemTargets.forEach(item => {
      item.draggable = false
      item.removeEventListener('dragstart', this.dragStart.bind(this))
      item.removeEventListener('dragover', this.dragOver.bind(this))
      item.removeEventListener('dragenter', this.dragEnter.bind(this))
      item.removeEventListener('dragleave', this.dragLeave.bind(this))
      item.removeEventListener('drop', this.drop.bind(this))
      item.removeEventListener('dragend', this.dragEnd.bind(this))
    })
  }

  dragStart(e) {
    this.draggedElement = e.target.closest('[data-sortable-waypoints-target="item"]')
    this.draggedElement.style.opacity = '0.5'

    // Create placeholder
    this.placeholder = document.createElement('div')
    this.placeholder.className = 'h-16 bg-blue-100 border-2 border-dashed border-blue-300 rounded-md flex items-center justify-center'
    this.placeholder.innerHTML = '<span class="text-blue-600 text-sm">Drop waypoint here</span>'

    e.dataTransfer.effectAllowed = 'move'
    e.dataTransfer.setData('text/html', this.draggedElement.outerHTML)
  }

  dragOver(e) {
    e.preventDefault()
    e.dataTransfer.dropEffect = 'move'
  }

  dragEnter(e) {
    e.preventDefault()
    const target = e.target.closest('[data-sortable-waypoints-target="item"]')
    if (target && target !== this.draggedElement) {
      const rect = target.getBoundingClientRect()
      const midpoint = rect.top + rect.height / 2

      if (e.clientY < midpoint) {
        target.parentNode.insertBefore(this.placeholder, target)
      } else {
        target.parentNode.insertBefore(this.placeholder, target.nextSibling)
      }
    }
  }

  dragLeave(e) {
    // Remove placeholder if we're leaving the container
    if (!this.element.contains(e.relatedTarget) && this.placeholder && this.placeholder.parentNode) {
      this.placeholder.parentNode.removeChild(this.placeholder)
    }
  }

  drop(e) {
    e.preventDefault()
    if (this.placeholder && this.placeholder.parentNode) {
      // Insert dragged element at placeholder position
      this.placeholder.parentNode.insertBefore(this.draggedElement, this.placeholder)
      this.placeholder.parentNode.removeChild(this.placeholder)

      // Update positions and refresh map
      this.updateWaypointPositions()
    }
  }

  dragEnd(e) {
    if (this.draggedElement) {
      this.draggedElement.style.opacity = ''
      this.draggedElement = null
    }

    if (this.placeholder && this.placeholder.parentNode) {
      this.placeholder.parentNode.removeChild(this.placeholder)
      this.placeholder = null
    }
  }

  updateWaypointPositions() {
    // Update the position numbers in the UI
    this.itemTargets.forEach((item, index) => {
      const positionBadge = item.querySelector('.waypoint-position-badge')
      const positionText = item.querySelector('.waypoint-position-text')
      const newPosition = index + 1

      if (positionBadge) {
        positionBadge.textContent = newPosition.toString()
      }
      if (positionText) {
        positionText.textContent = `Waypoint ${newPosition}`
      }

      // Store the new position on the element
      item.dataset.position = newPosition.toString()
    })

    // Find the map controller directly and call the update method
    const mapElement = document.getElementById('edit-waypoints-map')
    if (mapElement) {
      const mapController = this.application.getControllerForElementAndIdentifier(mapElement, 'edit-waypoints-map')
      if (mapController && mapController.updateWaypointPositionsFromList) {
        mapController.updateWaypointPositionsFromList()
      }
    }
  }

  // Called when new waypoints are added to refresh drag listeners
  refreshDragListeners() {
    this.removeDragListeners()
    this.attachDragListeners()
  }
}