require 'rails_helper'

RSpec.describe PackingListItemsController, type: :request do
  let(:owner) { create(:user) }
  let(:participant) { create(:user) }
  let(:road_trip) { create(:road_trip, user: owner) }

  def sign_in_user(user)
    post login_path, params: { username: user.username, password: "password123" }
  end

  before do
    road_trip.add_participant(participant)
  end

  context "when the list belongs to the current user" do
    let(:packing_list) { create(:packing_list, :private_list, road_trip: road_trip, user: owner) }
    let!(:item) { create(:packing_list_item, packing_list: packing_list) }

    before { sign_in_user(owner) }

    it "toggles the packed status" do
      patch toggle_packed_road_trip_packing_list_packing_list_item_path(road_trip, packing_list, item)

      expect(response).to redirect_to(road_trip_packing_list_path(road_trip, packing_list))
      expect(item.reload.packed).to be true
    end
  end

  context "when another participant owns a private list" do
    let(:packing_list) { create(:packing_list, :private_list, road_trip: road_trip, user: owner) }
    let!(:item) { create(:packing_list_item, packing_list: packing_list) }

    before { sign_in_user(participant) }

    it "does not reveal the edit form" do
      get edit_road_trip_packing_list_packing_list_item_path(road_trip, packing_list, item)

      expect(response).to redirect_to(road_trips_path)
    end

    it "does not allow deleting items" do
      expect {
        delete road_trip_packing_list_packing_list_item_path(road_trip, packing_list, item)
      }.not_to change(PackingListItem, :count)
    end
  end

  context "when another participant owns a public list" do
    let(:packing_list) { create(:packing_list, :public_list, road_trip: road_trip, user: owner) }
    let!(:item) { create(:packing_list_item, packing_list: packing_list) }

    before { sign_in_user(participant) }

    it "does not allow toggling items" do
      patch toggle_packed_road_trip_packing_list_packing_list_item_path(road_trip, packing_list, item)

      expect(response).to redirect_to(road_trip_packing_list_path(road_trip, packing_list))
      expect(item.reload.packed).to be false
    end

    it "does not allow adding items" do
      expect {
        post road_trip_packing_list_packing_list_items_path(road_trip, packing_list),
             params: { packing_list_item: { name: "Tent", quantity: 1, category: "tools" } }
      }.not_to change(PackingListItem, :count)
    end
  end
end
