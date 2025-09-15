require 'rails_helper'

RSpec.describe "Packing Lists Privacy", type: :system do
  let(:owner) { create(:user, username: "trip_owner") }
  let(:participant) { create(:user, username: "participant") }
  let(:road_trip) { create(:road_trip, user: owner) }

  before do
    # Add participant to the road trip
    road_trip.add_participant(participant)
  end

  describe "viewing packing lists as a participant" do
    let!(:private_list) { create(:packing_list, name: "Owner's Private List", visibility: "private", road_trip: road_trip, user: owner) }
    let!(:public_list) { create(:packing_list, name: "Owner's Public List", visibility: "public", road_trip: road_trip, user: owner) }

    before do
      login_as(participant)
    end

    it "shows public lists created by other users with creator information" do
      visit road_trip_packing_lists_path(road_trip)

      # Should see the public list
      expect(page).to have_content("Owner's Public List")
      expect(page).to have_content("by trip_owner")
      expect(page).to have_content("Public")

      # Should NOT see the private list
      expect(page).not_to have_content("Owner's Private List")
    end

    it "displays creator username correctly when viewing a public list" do
      visit road_trip_packing_list_path(road_trip, public_list)

      # Should show the list with creator information
      expect(page).to have_content("Owner's Public List")
      expect(page).to have_content("Created by trip_owner")
      expect(page).to have_content("Public list")

      # Should not show edit controls since participant doesn't own it
      expect(page).not_to have_link("Edit")
      expect(page).not_to have_link("Add Item")
      expect(page).to have_link("Back to Lists")
    end
  end

  describe "viewing packing lists as owner" do
    let!(:private_list) { create(:packing_list, name: "My Private List", visibility: "private", road_trip: road_trip, user: owner) }
    let!(:public_list) { create(:packing_list, name: "My Public List", visibility: "public", road_trip: road_trip, user: owner) }

    before do
      login_as(owner)
    end

    it "shows all own lists with edit controls" do
      visit road_trip_packing_lists_path(road_trip)

      # Should see both lists
      expect(page).to have_content("My Private List")
      expect(page).to have_content("My Public List")
      expect(page).to have_content("Private")
      expect(page).to have_content("Public")

      # Should have edit controls for own lists (general check)
      expect(page).to have_css("a[href*='edit']")
    end

    it "displays own list without creator information" do
      visit road_trip_packing_list_path(road_trip, private_list)

      # Should show the list
      expect(page).to have_content("My Private List")
      expect(page).to have_content("Private list")

      # Should NOT show "Created by" since it's own list
      expect(page).not_to have_content("Created by")

      # Should show edit controls since owner owns it
      expect(page).to have_link("Edit")
      expect(page).to have_link("Add Item")
    end
  end

  describe "UI displays correctly without errors" do
    before do
      login_as(owner)
    end

    it "new packing list form loads without errors" do
      visit new_road_trip_packing_list_path(road_trip)

      expect(page).to have_content("Create New Packing List")
      expect(page).to have_field("Packing List Name")
      expect(page).to have_content("Visibility")
      expect(page).to have_button("Create Packing List")
    end

    it "edit packing list form loads without errors" do
      private_list = create(:packing_list, name: "Editable List", visibility: "private", road_trip: road_trip, user: owner)

      visit edit_road_trip_packing_list_path(road_trip, private_list)

      expect(page).to have_content("Edit Packing List")
      expect(page).to have_field("Packing List Name", with: "Editable List")
      expect(page).to have_content("Visibility")
      expect(page).to have_button("Update Packing List")
    end
  end

  private

  def login_as(user)
    visit login_path
    fill_in 'Username', with: user.username
    fill_in 'Password', with: 'password123'
    click_button 'Sign In'
  end
end