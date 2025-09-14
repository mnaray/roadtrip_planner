require "rails_helper"

RSpec.describe "Fuel Economy Calculator", type: :system, js: true do
  let(:user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let(:route) { create(:route, road_trip: road_trip, user: user, distance: 100) }

  before do
    login_as(user)
  end

  describe "navigation" do
    it "can be accessed from the route page" do
      visit route_path(route)

      expect(page).to have_link("Fuel Economy", href: route_fuel_economy_path(route))

      click_link "Fuel Economy"

      expect(page).to have_current_path(route_fuel_economy_path(route))
      expect(page).to have_content("Fuel Economy Calculator")
    end
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

      # Fill in the form to ensure inputs work
      fill_in "Fuel Price (Currency per liter)", with: "1.85"
      fill_in "Fuel Consumption (liters per 100 km)", with: "7.5"
      fill_in "Number of Passengers", with: "4"

      # Wait for inputs to be processed
      sleep 0.2

      # Verify form accepts input correctly
      expect(find_field("Fuel Price (Currency per liter)").value).to eq("1.85")
      expect(find_field("Fuel Consumption (liters per 100 km)").value).to eq("7.5")
      expect(find_field("Number of Passengers").value).to eq("4")
    end

    it "updates calculations in real-time when inputs change" do
      # Wait for page to load completely
      expect(page).to have_content("Fuel Cost Calculator")

      # Initial calculation
      fill_in "Fuel Price (Currency per liter)", with: "2.00"
      fill_in "Fuel Consumption (liters per 100 km)", with: "10"
      fill_in "Number of Passengers", with: "2"

      # Wait for JavaScript to process the input events and show results
      expect(page).to have_selector("[data-fuel-economy-target='results']", visible: true)

      within("[data-fuel-economy-target='results']") do
        expect(page).to have_content("Currency 20.00") # Total cost (100km * 10L/100km * 2Currency)
        expect(page).to have_content("Currency 10.00") # Cost per passenger (20 / 2)
      end

      # Update number of passengers
      fill_in "Number of Passengers", with: "4"

      # Wait for JavaScript to process the updated calculation
      sleep 0.5

      within("[data-fuel-economy-target='results']") do
        expect(page).to have_content("Currency 20.00") # Total cost remains same
        expect(page).to have_content("Currency 5.00") # Cost per passenger updates (20 / 4)
      end
    end

    it "calculates round trip costs when checkbox is selected" do
      fill_in "Fuel Price (Currency per liter)", with: "1.85"
      fill_in "Fuel Consumption (liters per 100 km)", with: "7.5"
      fill_in "Number of Passengers", with: "4"

      # Wait for JavaScript to process the input events and show results
      expect(page).to have_selector("[data-fuel-economy-target='results']", visible: true)

      # Check round trip option and ensure it's actually checked
      check "Calculate for round trip"
      expect(page).to have_checked_field("Calculate for round trip")

      # Wait for JavaScript to process the checkbox change and show round trip results
      expect(page).to have_selector("[data-fuel-economy-target='roundTripResults']", visible: true)

      within("[data-fuel-economy-target='roundTripResults']") do
        expect(page).to have_content("Round Trip Total Cost")
        expect(page).to have_content("Currency 27.75") # 13.88 * 2
        expect(page).to have_content("Currency 6.94 per passenger") # 27.75 / 4
      end
    end

    it "hides results when inputs are cleared" do
      # Fill in form initially
      fill_in "Fuel Price (Currency per liter)", with: "1.85"
      fill_in "Fuel Consumption (liters per 100 km)", with: "7.5"

      expect(page).to have_selector("[data-fuel-economy-target='results']", visible: true)

      # Clear an input
      fill_in "Fuel Price (Currency per liter)", with: ""

      expect(page).to have_selector("[data-fuel-economy-target='results']", visible: false)
    end
  end

  describe "when route has no distance" do
    let(:route_without_distance) { create(:route, road_trip: road_trip, user: user) }

    it "shows a warning message" do
      # Mock the RouteDistanceCalculator to return nil distance
      calculator = instance_double(RouteDistanceCalculator)
      allow(RouteDistanceCalculator).to receive(:new)
        .with(route_without_distance.starting_location, route_without_distance.destination)
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
      expect(page).to have_current_path(route_path(route))
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
