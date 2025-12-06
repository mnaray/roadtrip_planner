require 'rails_helper'

RSpec.describe "Vehicles", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }

  before do
    login_as(user)
  end

  describe "GET /garage" do
    let!(:vehicle1) { create(:vehicle, user: user, name: "Car 1") }
    let!(:vehicle2) { create(:vehicle, :default, user: user, name: "Car 2") }

    it "displays all user vehicles" do
      get "/garage"
      expect(response).to have_http_status(:ok)
    end
  end

  describe "GET /vehicles/:id" do
    let!(:vehicle) { create(:vehicle, user: user) }

    it "shows the vehicle when user owns it" do
      get "/garage/vehicles/#{vehicle.id}"
      expect(response).to have_http_status(:ok)
    end

    it "redirects when vehicle doesn't belong to user" do
      other_vehicle = create(:vehicle, user: other_user)
      get "/garage/vehicles/#{other_vehicle.id}"
      expect(response).to redirect_to("/garage")
    end
  end

  describe "POST /vehicles" do
    let(:valid_attributes) do
      {
        name: "My New Car",
        vehicle_type: "car",
        make_model: "Honda Civic",
        engine_volume_ccm: 1800,
        horsepower: 140,
        fuel_consumption: 6.5
      }
    end

    context "with valid parameters" do
      it "creates a new vehicle" do
        expect {
          post "/garage/vehicles", params: { vehicle: valid_attributes }
        }.to change(Vehicle, :count).by(1)
        expect(response).to redirect_to("/garage")
      end

      it "sets first vehicle as default automatically" do
        post "/garage/vehicles", params: { vehicle: valid_attributes }
        expect(user.vehicles.last.is_default).to be true
      end

      it "does not set as default if user already has vehicles" do
        create(:vehicle, :default, user: user)
        post "/garage/vehicles", params: { vehicle: valid_attributes }
        expect(user.vehicles.last.is_default).to be false
      end
    end

    context "with invalid parameters" do
      it "does not create a vehicle" do
        expect {
          post "/garage/vehicles", params: { vehicle: { name: "" } }
        }.not_to change(Vehicle, :count)
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "PATCH /vehicles/:id" do
    let!(:vehicle) { create(:vehicle, user: user) }
    let(:new_attributes) { { name: "Updated Name" } }

    context "with valid parameters" do
      it "updates the vehicle" do
        patch "/garage/vehicles/#{vehicle.id}", params: { vehicle: new_attributes }
        vehicle.reload
        expect(vehicle.name).to eq("Updated Name")
        expect(response).to redirect_to("/garage")
      end
    end

    context "with invalid parameters" do
      it "does not update the vehicle" do
        patch "/garage/vehicles/#{vehicle.id}", params: { vehicle: { name: "" } }
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /vehicles/:id" do
    context "when deleting default vehicle with other vehicles present" do
      let!(:oldest_vehicle) { create(:vehicle, user: user, name: "Oldest", created_at: 3.days.ago) }
      let!(:middle_vehicle) { create(:vehicle, user: user, name: "Middle", created_at: 2.days.ago) }
      let!(:newest_vehicle) { create(:vehicle, user: user, name: "Newest", created_at: 1.day.ago) }
      let!(:default_vehicle) { create(:vehicle, :default, user: user, name: "Default", created_at: 4.days.ago) }

      it "deletes the default vehicle and sets newest as new default" do
        expect {
          delete "/garage/vehicles/#{default_vehicle.id}"
        }.to change(Vehicle, :count).by(-1)

        expect(response).to redirect_to("/garage")
        expect(newest_vehicle.reload.is_default).to be true
        expect(middle_vehicle.reload.is_default).to be false
        expect(oldest_vehicle.reload.is_default).to be false
      end

      it "includes success message mentioning the deleted vehicle" do
        delete "/garage/vehicles/#{default_vehicle.id}"
        follow_redirect!
        expect(response.body).to include("Default was successfully removed from your garage")
      end
    end

    context "when deleting non-default vehicle" do
      let!(:default_vehicle) { create(:vehicle, :default, user: user, name: "Default") }
      let!(:regular_vehicle) { create(:vehicle, user: user, name: "Regular") }

      it "deletes the vehicle without affecting default status" do
        expect {
          delete "/garage/vehicles/#{regular_vehicle.id}"
        }.to change(Vehicle, :count).by(-1)

        expect(response).to redirect_to("/garage")
        expect(default_vehicle.reload.is_default).to be true
      end
    end

    context "when deleting the only vehicle" do
      let!(:only_vehicle) { create(:vehicle, :default, user: user) }

      it "deletes the vehicle successfully" do
        expect {
          delete "/garage/vehicles/#{only_vehicle.id}"
        }.to change(Vehicle, :count).by(-1)

        expect(response).to redirect_to("/garage")
        expect(user.vehicles.count).to eq(0)
      end
    end

    context "when trying to delete another user's vehicle" do
      let!(:other_vehicle) { create(:vehicle, user: other_user) }

      it "redirects to garage with error message" do
        delete "/garage/vehicles/#{other_vehicle.id}"
        expect(response).to redirect_to("/garage")
      end

      it "does not delete the vehicle" do
        expect {
          delete "/garage/vehicles/#{other_vehicle.id}"
        }.not_to change(Vehicle, :count)
      end
    end
  end

  describe "PATCH /vehicles/:id/set_default" do
    let!(:current_default) { create(:vehicle, :default, user: user, name: "Current Default") }
    let!(:new_default) { create(:vehicle, user: user, name: "New Default") }

    it "sets the vehicle as default and unsets the previous default" do
      patch "/garage/vehicles/#{new_default.id}/set_default"

      expect(response).to redirect_to("/garage")
      expect(new_default.reload.is_default).to be true
      expect(current_default.reload.is_default).to be false
    end

    it "includes success message mentioning the new default vehicle" do
      patch "/garage/vehicles/#{new_default.id}/set_default"
      follow_redirect!
      expect(response.body).to include("New Default is now your default vehicle")
    end

    context "when trying to set another user's vehicle as default" do
      let!(:other_vehicle) { create(:vehicle, user: other_user) }

      it "redirects to garage without changing defaults" do
        patch "/garage/vehicles/#{other_vehicle.id}/set_default"
        expect(response).to redirect_to("/garage")
        expect(current_default.reload.is_default).to be true
      end
    end
  end

  private

  def login_as(user)
    allow_any_instance_of(ApplicationController).to receive(:current_user).and_return(user)
  end
end