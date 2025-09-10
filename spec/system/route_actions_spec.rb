require 'rails_helper'

RSpec.describe "Route Actions", type: :system do
  let(:user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let!(:route) { create(:route, road_trip: road_trip, user: user) }

  def sign_in(user)
    visit login_path
    within "form" do
      fill_in "Username", with: user.username
      fill_in "Password", with: "password123"
      click_button "Sign In"
    end
  end

  before do
    sign_in(user)
  end

  describe "Road Trip Show Page Route Actions" do
    before do
      visit road_trip_path(road_trip)
    end

    it "displays route action buttons" do
      # Check for edit button in the actions area
      expect(page).to have_link(href: edit_route_path(route))

      # Check for delete button (now a button_to form)
      expect(page).to have_button(class: /text-gray-400.*hover:text-red-600/)
    end

    it "clicking on route navigates to route map" do
      # Click on the route row (not the action buttons)
      find("a[href='#{route_map_path(route)}']").click

      expect(page).to have_current_path(route_map_path(route))
      expect(page).to have_content("Route Map")
      expect(page).to have_content(route.starting_location)
      expect(page).to have_content(route.destination)
    end

    it "edit button navigates to edit page" do
      find("a[href='#{edit_route_path(route)}']").click

      expect(page).to have_current_path(edit_route_path(route))
      expect(page).to have_content("Edit Route")
    end

    it "delete button removes the route" do
      # Find and click the delete button (which is now a form button)
      find("form[action='#{route_path(route)}'] button").click

      expect(page).to have_content("Route was successfully deleted")
      expect(page).not_to have_content(route.starting_location)
      expect(Route.exists?(route.id)).to be_falsey
    end
  end

  describe "Route Map Page Actions" do
    before do
      visit route_map_path(route)
    end

    it "displays all action buttons" do
      expect(page).to have_link("Edit Route", href: edit_route_path(route))
      expect(page).to have_link("Download GPX", href: route_export_gpx_path(route))
      expect(page).to have_button("Delete Route")
    end

    it "edit button navigates to edit page" do
      click_link "Edit Route"

      expect(page).to have_current_path(edit_route_path(route))
      expect(page).to have_content("Edit Route")
    end

    it "download GPX button initiates download" do
      # This tests that the link exists and has the correct href
      # Actual download testing would require different approach
      gpx_link = find_link("Download GPX")
      expect(gpx_link[:href]).to eq(route_export_gpx_path(route))
    end

    it "delete button removes the route and redirects" do
      click_button "Delete Route"

      expect(page).to have_current_path(road_trip_path(road_trip))
      expect(page).to have_content("Route was successfully deleted")
      expect(Route.exists?(route.id)).to be_falsey
    end

    it "back button returns to road trip" do
      click_link "Back to Road Trip"

      expect(page).to have_current_path(road_trip_path(road_trip))
    end
  end

  describe "Edit Route Page Actions" do
    before do
      visit edit_route_path(route)
    end

    it "displays form with current route data" do
      expect(page).to have_field("Starting Location", with: route.starting_location)
      expect(page).to have_field("Destination", with: route.destination)
    end

    it "cancel button returns to road trip" do
      click_link "Cancel"

      expect(page).to have_current_path(road_trip_path(road_trip))
    end

    it "update button saves changes" do
      fill_in "Starting Location", with: "New Start Location"
      fill_in "Destination", with: "New End Location"
      click_button "Update Route"

      expect(page).to have_current_path(road_trip_path(road_trip))
      expect(page).to have_content("Route was successfully updated")
      expect(page).to have_content("New Start Location")
      expect(page).to have_content("New End Location")
    end
  end

  describe "Road Trip Edit Page Delete Action" do
    before do
      visit edit_road_trip_path(road_trip)
    end

    it "displays delete road trip button" do
      expect(page).to have_button("Delete Road Trip")
    end

    it "delete button removes the road trip" do
      click_button "Delete Road Trip"

      expect(page).to have_current_path(road_trips_path)
      expect(page).to have_content("Road trip was successfully deleted")
      expect(RoadTrip.exists?(road_trip.id)).to be_falsey
    end
  end
end
