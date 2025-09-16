require "rails_helper"

RSpec.describe "Fuel Economy Calculator", type: :system, js: true do
  let(:user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let(:route) { create(:route, road_trip: road_trip, user: user, distance: 100) }

  before do
    login_as(user)
  end


  describe "calculator functionality" do
    before do
      visit route_fuel_economy_path(route)
    end

    it "displays route information" do
      expect(page).to have_content(route.starting_location)
      expect(page).to have_content(route.destination)
      expect(page).to have_content("100 km") # Default distance from RouteDistanceCalculator mock
    end

    it "displays the fuel cost calculator with all necessary form fields" do
      # Verify page loads correctly
      expect(page).to have_content("Fuel Cost Calculator")

      # Check all form fields are present for user input
      expect(page).to have_field("Fuel Price (Currency per liter)")
      expect(page).to have_field("Fuel Consumption (liters per 100 km)")
      expect(page).to have_field("Number of Passengers")

      # Verify the form has proper Stimulus controller setup for real-time calculations
      expect(page).to have_selector("[data-controller='fuel-economy']")
      expect(page).to have_selector("[data-fuel-economy-target='fuelPrice']")
      expect(page).to have_selector("[data-fuel-economy-target='fuelConsumption']")
      expect(page).to have_selector("[data-fuel-economy-target='numPassengers']")

      # Check results section exists with proper targets for JavaScript updates (may be hidden initially)
      expect(page).to have_selector("[data-fuel-economy-target='results']", visible: :all)
      expect(page).to have_selector("[data-fuel-economy-target='totalFuel']", visible: :all)
      expect(page).to have_selector("[data-fuel-economy-target='totalCost']", visible: :all)
      expect(page).to have_selector("[data-fuel-economy-target='costPerPassenger']", visible: :all)
      expect(page).to have_selector("[data-fuel-economy-target='costPerKm']", visible: :all)

      # Verify round trip functionality is available
      expect(page).to have_selector("[data-fuel-economy-target='roundTrip']", visible: :all)
      expect(page).to have_selector("[data-fuel-economy-target='roundTripResults']", visible: :all)
    end
  end

  describe "when route has no distance" do
    let(:route_without_distance) { create(:route, road_trip: road_trip, user: user) }

    it "shows a warning message" do
      # Mock the RouteDistanceCalculator to return nil distance
      calculator = instance_double(RouteDistanceCalculator)
      allow(RouteDistanceCalculator).to receive(:new)
        .with(route_without_distance.starting_location, route_without_distance.destination, [], avoid_motorways: false)
        .and_return(calculator)
      allow(calculator).to receive(:calculate).and_return({ distance: nil, duration: nil })

      # Force recalculation of route metrics to use the mock
      route_without_distance.send(:calculate_route_metrics)
      route_without_distance.save!

      visit route_fuel_economy_path(route_without_distance)

      expect(page).to have_content("Distance not available")
      expect(page).to have_content("The distance for this route could not be calculated")
    end
  end

  describe "breadcrumb navigation" do
    before do
      visit route_fuel_economy_path(route)
    end

    it "displays proper breadcrumb trail" do
      within("nav[aria-label='Breadcrumb']") do
        expect(page).to have_link("My Road Trips", href: road_trips_path)
        expect(page).to have_link(road_trip.name, href: road_trip_path(road_trip))
        expect(page).to have_link("Route: #{route.starting_location} → #{route.destination}", href: route_path(route))
        expect(page).to have_content("Fuel Economy")
      end
    end

    it "can navigate back to route page" do
      click_link "Back to Route"
      expect(page).to have_current_path(route_path(route), wait: 5)
    end
  end

  private

  def login_as(user)
    visit login_path
    fill_in "Username", with: user.username
    fill_in "Password", with: "password123"
    click_button "Sign In"

    # Wait for login to complete and redirect
    expect(page).to have_content("Welcome, #{user.username}!")
  end
end
