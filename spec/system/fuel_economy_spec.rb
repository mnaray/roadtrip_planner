require "rails_helper"

RSpec.describe "Fuel Economy Calculator", type: :system, js: true do
  let(:user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let(:route) { create(:route, road_trip: road_trip, user: user, distance: 200) }

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

    xit "calculates fuel costs when all inputs are provided" do
      # Fill in the form
      fill_in "Fuel Price (Currency per liter)", with: "1.85"
      fill_in "Fuel Consumption (liters per 100 km)", with: "7.5"
      fill_in "Number of Passengers", with: "4"

      # Check that results are displayed (100km distance)
      within("[data-fuel-economy-target='results']") do
        expect(page).to have_content("Total Fuel Needed")
        expect(page).to have_content("7.5 L") # 100km * 7.5L/100km

        expect(page).to have_content("Total Fuel Cost")
        expect(page).to have_content("Currency 13.88") # 7.5L * 1.85

        expect(page).to have_content("Cost per Passenger")
        expect(page).to have_content("Currency 3.47") # 13.88 / 4

        expect(page).to have_content("Cost per Kilometer")
        expect(page).to have_content("Currency 0.139") # 13.88 / 100
      end
    end

    xit "updates calculations in real-time when inputs change" do
      # Initial calculation
      fill_in "Fuel Price (Currency per liter)", with: "2.00"
      fill_in "Fuel Consumption (liters per 100 km)", with: "10"
      fill_in "Number of Passengers", with: "2"

      within("[data-fuel-economy-target='results']") do
        expect(page).to have_content("Currency 20.00") # Total cost (100km * 10L/100km * 2Currency)
        expect(page).to have_content("Currency 10.00") # Cost per passenger (20 / 2)
      end

      # Update number of passengers
      fill_in "Number of Passengers", with: "4"

      within("[data-fuel-economy-target='results']") do
        expect(page).to have_content("Currency 20.00") # Total cost remains same
        expect(page).to have_content("Currency 5.00") # Cost per passenger updates (20 / 4)
      end
    end

    xit "calculates round trip costs when checkbox is selected" do
      fill_in "Fuel Price (Currency per liter)", with: "1.85"
      fill_in "Fuel Consumption (liters per 100 km)", with: "7.5"
      fill_in "Number of Passengers", with: "4"

      # Check round trip option
      check "Calculate for round trip"

      within("[data-fuel-economy-target='roundTripResults']") do
        expect(page).to have_content("Round Trip Total Cost")
        expect(page).to have_content("Currency 27.75") # 13.88 * 2
        expect(page).to have_content("Currency 6.94 per passenger") # 27.75 / 4
      end
    end

    xit "hides results when inputs are cleared" do
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
    let(:route_without_distance) { create(:route, road_trip: road_trip, user: user, distance: nil) }

    before do
      # Stub the distance calculation to return nil for this specific route
      allow(route_without_distance).to receive(:distance_in_km).and_return(nil)
    end

    xit "shows a warning message" do
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
  end
end
