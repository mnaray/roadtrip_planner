require 'rails_helper'

RSpec.describe "Waypoints", type: :request do
  let(:user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }

  # Helper to sign in user
  def sign_in_user(user)
    post login_path, params: { username: user.username, password: "password123" }
  end

  before do
    sign_in_user(user)
  end

  describe "GET /set_waypoints" do
    context "with valid route data in session" do
      before do
        session[:route_data] = {
          "road_trip_id" => road_trip.id,
          "starting_location" => "San Francisco, CA",
          "destination" => "Los Angeles, CA"
        }
      end

      it "renders the waypoints setting page" do
        get set_waypoints_path
        expect(response).to have_http_status(:success)
        expect(response.body).to include("Set Waypoints for Your Route")
        expect(response.body).to include("San Francisco, CA")
        expect(response.body).to include("Los Angeles, CA")
      end
    end

    context "with no route data in session" do
      it "redirects to road trips with alert" do
        get set_waypoints_path
        expect(response).to redirect_to(road_trips_path)
        follow_redirect!
        expect(response.body).to include("No route data found.")
      end
    end

    context "with unauthorized access to road trip" do
      let(:other_user) { create(:user) }
      let(:other_road_trip) { create(:road_trip, user: other_user) }

      before do
        session[:route_data] = {
          "road_trip_id" => other_road_trip.id,
          "starting_location" => "San Francisco, CA",
          "destination" => "Los Angeles, CA"
        }
      end

      it "redirects to road trips with alert" do
        get set_waypoints_path
        expect(response).to redirect_to(road_trips_path)
        follow_redirect!
        expect(response.body).to include("You don't have access to this road trip.")
      end
    end
  end

  describe "POST /set_waypoints" do
    let(:waypoints_data) do
      [
        { "latitude" => "37.7749", "longitude" => "-122.4194", "position" => 1 },
        { "latitude" => "34.0522", "longitude" => "-118.2437", "position" => 2 }
      ]
    end

    context "with valid route data in session" do
      before do
        session[:route_data] = {
          "road_trip_id" => road_trip.id,
          "starting_location" => "San Francisco, CA",
          "destination" => "Los Angeles, CA"
        }
      end

      it "stores waypoints data in session and redirects to confirm route" do
        post set_waypoints_path, params: { waypoints: waypoints_data }

        expect(response).to redirect_to(confirm_route_path)
        expect(session[:route_data]["waypoints"]).to eq(waypoints_data)
      end

      it "handles empty waypoints data" do
        post set_waypoints_path, params: { waypoints: [] }

        expect(response).to redirect_to(confirm_route_path)
        expect(session[:route_data]["waypoints"]).to eq([])
      end
    end

    context "with no route data in session" do
      it "redirects to road trips with alert" do
        post set_waypoints_path, params: { waypoints: waypoints_data }

        expect(response).to redirect_to(road_trips_path)
        follow_redirect!
        expect(response.body).to include("No route data found.")
      end
    end

    context "with unauthorized access to road trip" do
      let(:other_user) { create(:user) }
      let(:other_road_trip) { create(:road_trip, user: other_user) }

      before do
        session[:route_data] = {
          "road_trip_id" => other_road_trip.id,
          "starting_location" => "San Francisco, CA",
          "destination" => "Los Angeles, CA"
        }
      end

      it "redirects to road trips with alert" do
        post set_waypoints_path, params: { waypoints: waypoints_data }

        expect(response).to redirect_to(road_trips_path)
        follow_redirect!
        expect(response.body).to include("You don't have access to this road trip.")
      end
    end
  end

  describe "DELETE /waypoints/:id" do
    let(:route) { create(:route, road_trip: road_trip, user: user) }
    let!(:waypoint1) { create(:waypoint, route: route, position: 1, latitude: 37.7749, longitude: -122.4194) }
    let!(:waypoint2) { create(:waypoint, route: route, position: 2, latitude: 37.7849, longitude: -122.4094) }
    let!(:waypoint3) { create(:waypoint, route: route, position: 3, latitude: 37.7949, longitude: -122.3994) }

    it "deletes the waypoint and reorders remaining waypoints" do
      expect {
        delete waypoint_path(waypoint2), xhr: true
      }.to change(Waypoint, :count).by(-1)

      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response["status"]).to eq("success")

      # Check that remaining waypoints are reordered
      remaining_waypoints = route.waypoints.ordered
      expect(remaining_waypoints.count).to eq(2)
      expect(remaining_waypoints.first.position).to eq(1)
      expect(remaining_waypoints.second.position).to eq(2)
      expect(remaining_waypoints.first.id).to eq(waypoint1.id)
      expect(remaining_waypoints.second.id).to eq(waypoint3.id)
    end

    context "when user doesn't have access to the route" do
      let(:other_user) { create(:user) }
      let(:other_road_trip) { create(:road_trip, user: other_user) }
      let(:other_route) { create(:route, road_trip: other_road_trip, user: other_user) }
      let(:other_waypoint) { create(:waypoint, route: other_route, position: 1) }

      it "returns forbidden status" do
        delete waypoint_path(other_waypoint), xhr: true

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Access denied.")
      end
    end

    context "when waypoint doesn't exist" do
      it "returns not found status" do
        delete waypoint_path(999999), xhr: true

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Waypoint not found.")
      end
    end
  end
end
