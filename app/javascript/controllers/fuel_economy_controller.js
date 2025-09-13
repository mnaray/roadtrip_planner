import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="fuel-economy"
export default class extends Controller {
  static targets = [
    "fuelPrice",
    "fuelConsumption",
    "numPassengers",
    "results",
    "totalFuel",
    "totalCost",
    "costPerPassenger",
    "costPerKm",
    "roundTrip",
    "roundTripResults",
    "roundTripCost",
    "roundTripCostPerPassenger"
  ]

  static values = {
    distance: Number
  }

  connect() {
    // Initialize with any pre-filled values
    this.calculate()
  }

  calculate() {
    const fuelPrice = parseFloat(this.fuelPriceTarget.value) || 0
    const fuelConsumption = parseFloat(this.fuelConsumptionTarget.value) || 0
    const numPassengers = parseInt(this.numPassengersTarget.value) || 1
    const distance = this.distanceValue || 0
    const isRoundTrip = this.roundTripTarget.checked

    // Only show results if we have all required inputs
    if (fuelPrice > 0 && fuelConsumption > 0 && distance > 0) {
      // Calculate fuel needed (liters)
      const fuelNeeded = (distance * fuelConsumption) / 100

      // Calculate total cost
      const totalCost = fuelNeeded * fuelPrice

      // Calculate cost per passenger
      const costPerPassenger = totalCost / numPassengers

      // Calculate cost per km
      const costPerKm = totalCost / distance

      // Update display values
      this.totalFuelTarget.textContent = `${fuelNeeded.toFixed(1)} L`
      this.totalCostTarget.textContent = `Currency ${totalCost.toFixed(2)}`
      this.costPerPassengerTarget.textContent = `Currency ${costPerPassenger.toFixed(2)}`
      this.costPerKmTarget.textContent = `Currency ${costPerKm.toFixed(3)}`

      // Handle round trip calculations
      if (isRoundTrip) {
        const roundTripCost = totalCost * 2
        const roundTripCostPerPassenger = roundTripCost / numPassengers

        this.roundTripCostTarget.textContent = `Currency ${roundTripCost.toFixed(2)}`
        this.roundTripCostPerPassengerTarget.textContent = `Currency ${roundTripCostPerPassenger.toFixed(2)}`
        this.roundTripResultsTarget.classList.remove("hidden")
      } else {
        this.roundTripResultsTarget.classList.add("hidden")
      }

      // Show results section
      this.resultsTarget.style.display = "block"
    } else {
      // Hide results if inputs are incomplete
      this.resultsTarget.style.display = "none"
    }
  }
}