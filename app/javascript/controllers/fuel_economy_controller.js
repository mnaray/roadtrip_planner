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
    this.calculate()
  }

  calculate() {
    try {
      const fuelPrice = parseFloat(this.fuelPriceTarget?.value) || 0
      const fuelConsumption = parseFloat(this.fuelConsumptionTarget?.value) || 0
      const numPassengers = parseInt(this.numPassengersTarget?.value) || 1
      const distance = this.distanceValue || 0
      const isRoundTrip = this.roundTripTarget?.checked || false

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

        // Update display values with safe property access
        if (this.totalFuelTarget) this.totalFuelTarget.textContent = `${fuelNeeded.toFixed(1)} L`
        if (this.totalCostTarget) this.totalCostTarget.textContent = `Currency ${totalCost.toFixed(2)}`
        if (this.costPerPassengerTarget) this.costPerPassengerTarget.textContent = `Currency ${costPerPassenger.toFixed(2)}`
        if (this.costPerKmTarget) this.costPerKmTarget.textContent = `Currency ${costPerKm.toFixed(3)}`

        // Handle round trip calculations
        if (isRoundTrip && this.roundTripResultsTarget) {
          const roundTripCost = totalCost * 2
          const roundTripCostPerPassenger = roundTripCost / numPassengers

          if (this.roundTripCostTarget) this.roundTripCostTarget.textContent = `Currency ${roundTripCost.toFixed(2)}`
          if (this.roundTripCostPerPassengerTarget) this.roundTripCostPerPassengerTarget.textContent = `Currency ${roundTripCostPerPassenger.toFixed(2)}`
          this.roundTripResultsTarget.classList.remove("hidden")
        } else if (this.roundTripResultsTarget) {
          this.roundTripResultsTarget.classList.add("hidden")
        }

        // Show results section
        if (this.resultsTarget) this.resultsTarget.classList.remove("hidden")
      } else {
        // Hide results if inputs are incomplete
        if (this.resultsTarget) this.resultsTarget.classList.add("hidden")
      }
    } catch (error) {
      console.error("Error in fuel economy calculation:", error)
    }
  }
}