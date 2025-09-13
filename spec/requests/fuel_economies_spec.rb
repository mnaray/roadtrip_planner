require "rails_helper"

RSpec.describe "FuelEconomies", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let(:route) { create(:route, road_trip: road_trip, user: user) }

  # Helper to sign in user
  def sign_in_user(user)
    post login_path, params: { username: user.username, password: "password123" }
  end

  describe "GET /routes/:route_id/fuel_economy" do
    context "when not logged in" do
      it "redirects to login page" do
        get route_fuel_economy_path(route)
        expect(response).to redirect_to(login_path)
      end
    end

    context "when logged in as the route owner" do
      before { sign_in_user(user) }

      it "returns success" do
        get route_fuel_economy_path(route)
        expect(response).to have_http_status(:success)
      end

      it "renders the fuel economy calculator" do
        get route_fuel_economy_path(route)
        expect(response.body).to include("Fuel Economy Calculator")
        expect(response.body).to include(route.starting_location)
        expect(response.body).to include(route.destination)
      end
    end

    context "when logged in as a participant" do
      before do
        road_trip.add_participant(other_user)
        sign_in_user(other_user)
      end

      it "returns success" do
        get route_fuel_economy_path(route)
        expect(response).to have_http_status(:success)
      end
    end

    context "when logged in as a non-participant" do
      before { sign_in_user(other_user) }

      it "redirects with access denied message" do
        get route_fuel_economy_path(route)
        expect(response).to redirect_to(road_trips_path)
        expect(flash[:alert]).to eq("You don't have access to this route.")
      end
    end

    context "when route does not exist" do
      before { sign_in_user(user) }

      it "redirects with not found message" do
        get route_fuel_economy_path(route_id: 999999)
        expect(response).to redirect_to(road_trips_path)
        expect(flash[:alert]).to eq("Route not found.")
      end
    end
  end
end
