import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="sortable-waypoints"
export default class extends Controller {
  static targets = ["item"]

  connect() {
    this.makeItemsSortable()
  }

  itemTargetConnected(element) {
    this.makeItemsSortable()
  }

  itemTargetDisconnected(element) {
    this.makeItemsSortable()
  }

  // Performance optimization: Use event delegation instead of individual listeners
  makeItemsSortable() {
    // Set draggable attribute on items
    this.itemTargets.forEach(item => {
      item.draggable = true
    })

    // Use event delegation on the container
    this.attachDelegatedEventListeners()
  }

  attachDelegatedEventListeners() {
    // Remove existing delegated listeners to prevent duplicates
    this.element.removeEventListener('dragstart', this.delegatedDragStart)
    this.element.removeEventListener('dragover', this.delegatedDragOver)
    this.element.removeEventListener('drop', this.delegatedDrop)
    this.element.removeEventListener('dragend', this.delegatedDragEnd)

    // Create bound methods for event delegation
    this.delegatedDragStart = this.handleDelegatedDragStart.bind(this)
    this.delegatedDragOver = this.handleDelegatedDragOver.bind(this)
    this.delegatedDrop = this.handleDelegatedDrop.bind(this)
    this.delegatedDragEnd = this.handleDelegatedDragEnd.bind(this)

    // Add delegated listeners to container
    this.element.addEventListener('dragstart', this.delegatedDragStart)
    this.element.addEventListener('dragover', this.delegatedDragOver)
    this.element.addEventListener('drop', this.delegatedDrop)
    this.element.addEventListener('dragend', this.delegatedDragEnd)
  }

  handleDelegatedDragStart(e) {
    const target = e.target.closest('[data-sortable-waypoints-target="item"]')
    if (!target) return
    this.handleDragStart(e)
  }

  handleDelegatedDragOver(e) {
    const target = e.target.closest('[data-sortable-waypoints-target="item"]')
    if (!target) return
    this.handleDragOver(e)
  }

  handleDelegatedDrop(e) {
    const target = e.target.closest('[data-sortable-waypoints-target="item"]')
    if (!target) return
    this.handleDrop(e)
  }

  handleDelegatedDragEnd(e) {
    const target = e.target.closest('[data-sortable-waypoints-target="item"]')
    if (!target) return
    this.handleDragEnd(e)
  }

  handleDragStart(e) {
    this.draggedElement = e.target.closest('[data-sortable-waypoints-target="item"]')
    this.draggedElement.style.opacity = '0.5'
    e.dataTransfer.effectAllowed = 'move'

    // Create drop indicator line
    this.createDropIndicator()
  }

  handleDragOver(e) {
    e.preventDefault()
    e.dataTransfer.dropEffect = 'move'

    // Show drop indicator at the appropriate position
    this.showDropIndicator(e)
  }

  handleDrop(e) {
    e.preventDefault()

    if (!this.draggedElement) return

    const dropTarget = e.target.closest('[data-sortable-waypoints-target="item"]')
    if (!dropTarget || dropTarget === this.draggedElement) return

    // Get the parent container
    const container = this.draggedElement.parentNode

    // Determine if we should insert before or after the drop target
    const rect = dropTarget.getBoundingClientRect()
    const midpoint = rect.top + rect.height / 2

    if (e.clientY < midpoint) {
      container.insertBefore(this.draggedElement, dropTarget)
    } else {
      container.insertBefore(this.draggedElement, dropTarget.nextSibling)
    }

    // Update positions after reordering
    this.updatePositions()

    // Remove drop indicator
    this.removeDropIndicator()
  }

  handleDragEnd(e) {
    if (this.draggedElement) {
      this.draggedElement.style.opacity = ''
      this.draggedElement = null
    }

    // Remove drop indicator
    this.removeDropIndicator()
  }

  updatePositions() {
    // Update position badges and data attributes
    this.itemTargets.forEach((item, index) => {
      const newPosition = index + 1
      const badge = item.querySelector('.waypoint-position-badge')
      const text = item.querySelector('.waypoint-position-text')

      // Update visual elements
      if (badge) {
        badge.textContent = newPosition.toString()
      }
      if (text) {
        text.textContent = `Waypoint ${newPosition}`
      }

      // Update data attribute
      item.dataset.position = newPosition.toString()
    })

    // Notify the map controller about the position changes
    this.notifyMapController()
  }

  notifyMapController() {
    const mapElement = document.getElementById('edit-waypoints-map')
    if (!mapElement) return

    const mapController = this.application.getControllerForElementAndIdentifier(mapElement, 'edit-waypoints-map')
    if (mapController && mapController.updateWaypointPositionsFromList) {
      mapController.updateWaypointPositionsFromList()
    }
  }

  createDropIndicator() {
    // Create a visual drop indicator line
    this.dropIndicator = document.createElement('div')
    this.dropIndicator.className = 'drop-indicator'
    this.dropIndicator.style.cssText = `
      height: 3px;
      background: linear-gradient(90deg, #3B82F6, #60A5FA);
      border-radius: 2px;
      margin: 2px 0;
      opacity: 0;
      transform: scaleX(0);
      transform-origin: center;
      transition: all 0.2s ease;
      box-shadow: 0 0 8px rgba(59, 130, 246, 0.6);
      position: relative;
    `

    // Add arrow indicators on the sides
    const leftArrow = document.createElement('div')
    leftArrow.style.cssText = `
      position: absolute;
      left: -6px;
      top: -3px;
      width: 0;
      height: 0;
      border-top: 4px solid transparent;
      border-bottom: 4px solid transparent;
      border-right: 6px solid #3B82F6;
    `

    const rightArrow = document.createElement('div')
    rightArrow.style.cssText = `
      position: absolute;
      right: -6px;
      top: -3px;
      width: 0;
      height: 0;
      border-top: 4px solid transparent;
      border-bottom: 4px solid transparent;
      border-left: 6px solid #3B82F6;
    `

    this.dropIndicator.appendChild(leftArrow)
    this.dropIndicator.appendChild(rightArrow)
  }

  // Performance optimization: Improved drop indicator with RAF and reduced DOM manipulation
  showDropIndicator(e) {
    if (!this.draggedElement || !this.dropIndicator) return

    const dropTarget = e.target.closest('[data-sortable-waypoints-target="item"]')
    if (!dropTarget || dropTarget === this.draggedElement) {
      this.hideDropIndicator()
      return
    }

    // Calculate where to show the indicator
    const rect = dropTarget.getBoundingClientRect()
    const midpoint = rect.top + rect.height / 2
    const shouldInsertBefore = e.clientY < midpoint

    // Only move indicator if position actually changed
    let targetElement = shouldInsertBefore ? dropTarget : dropTarget.nextSibling
    if (this.dropIndicator.nextElementSibling !== targetElement) {
      // Use document fragment for efficient DOM manipulation
      if (this.dropIndicator.parentNode) {
        this.dropIndicator.parentNode.removeChild(this.dropIndicator)
      }

      if (shouldInsertBefore) {
        dropTarget.parentNode.insertBefore(this.dropIndicator, dropTarget)
      } else {
        dropTarget.parentNode.insertBefore(this.dropIndicator, dropTarget.nextSibling)
      }

      // Animate the indicator in with RAF for smooth animation
      if (!this.indicatorAnimationFrame) {
        this.indicatorAnimationFrame = requestAnimationFrame(() => {
          this.dropIndicator.style.opacity = '1'
          this.dropIndicator.style.transform = 'scaleX(1)'
          this.indicatorAnimationFrame = null
        })
      }
    }
  }

  hideDropIndicator() {
    if (this.indicatorAnimationFrame) {
      cancelAnimationFrame(this.indicatorAnimationFrame)
      this.indicatorAnimationFrame = null
    }
    this.dropIndicator.style.opacity = '0'
    this.dropIndicator.style.transform = 'scaleX(0)'
  }

  removeDropIndicator() {
    if (this.dropIndicator) {
      // Animate out
      this.dropIndicator.style.opacity = '0'
      this.dropIndicator.style.transform = 'scaleX(0)'

      // Remove after animation
      setTimeout(() => {
        if (this.dropIndicator && this.dropIndicator.parentNode) {
          this.dropIndicator.parentNode.removeChild(this.dropIndicator)
        }
        this.dropIndicator = null
      }, 200)
    }
  }
}