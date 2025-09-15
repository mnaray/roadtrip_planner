require 'rails_helper'

RSpec.describe WaypointsController, type: :controller do
  let(:user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }

  # Helper to sign in user for controller specs
  def sign_in_user(user)
    session[:user_id] = user.id
  end

  before do
    sign_in_user(user)
  end

  describe "GET set_waypoints" do
    context "with valid route data in session" do
      it "renders the waypoints setting page" do
        session[:route_data] = {
          "road_trip_id" => road_trip.id,
          "starting_location" => "San Francisco, CA",
          "destination" => "Los Angeles, CA"
        }

        get :set_waypoints
        expect(response).to have_http_status(:success)
      end
    end

    context "with no route data in session" do
      it "redirects to road trips with alert" do
        get :set_waypoints
        expect(response).to redirect_to(road_trips_path)
        expect(flash[:alert]).to eq("No route data found.")
      end
    end

    context "with unauthorized access to road trip" do
      let(:other_user) { create(:user) }
      let(:other_road_trip) { create(:road_trip, user: other_user) }

      it "redirects to road trips with alert" do
        session[:route_data] = {
          "road_trip_id" => other_road_trip.id,
          "starting_location" => "San Francisco, CA",
          "destination" => "Los Angeles, CA"
        }

        get :set_waypoints
        expect(response).to redirect_to(road_trips_path)
        expect(flash[:alert]).to eq("You don't have access to this road trip.")
      end
    end
  end

  describe "POST create" do
    let(:waypoints_data) do
      [
        { "latitude" => "37.7749", "longitude" => "-122.4194", "position" => 1 },
        { "latitude" => "34.0522", "longitude" => "-118.2437", "position" => 2 }
      ]
    end

    context "with valid route data in session" do
      it "stores waypoints data in session and redirects to confirm route" do
        session[:route_data] = {
          "road_trip_id" => road_trip.id,
          "starting_location" => "San Francisco, CA",
          "destination" => "Los Angeles, CA"
        }

        post :create, params: { waypoints: waypoints_data }

        expect(response).to redirect_to(confirm_route_path)
        expect(session[:route_data]["waypoints"]).to be_present
        expect(session[:route_data]["waypoints"].length).to eq(2)
      end

      it "handles empty waypoints data" do
        session[:route_data] = {
          "road_trip_id" => road_trip.id,
          "starting_location" => "San Francisco, CA",
          "destination" => "Los Angeles, CA"
        }

        post :create, params: { waypoints: [] }

        expect(response).to redirect_to(confirm_route_path)
        expect(session[:route_data]["waypoints"]).to eq([])
      end
    end

    context "with no route data in session" do
      it "redirects to road trips with alert" do
        post :create, params: { waypoints: waypoints_data }

        expect(response).to redirect_to(road_trips_path)
        expect(flash[:alert]).to eq("No route data found.")
      end
    end

    context "with unauthorized access to road trip" do
      let(:other_user) { create(:user) }
      let(:other_road_trip) { create(:road_trip, user: other_user) }

      it "redirects to road trips with alert" do
        session[:route_data] = {
          "road_trip_id" => other_road_trip.id,
          "starting_location" => "San Francisco, CA",
          "destination" => "Los Angeles, CA"
        }

        post :create, params: { waypoints: waypoints_data }

        expect(response).to redirect_to(road_trips_path)
        expect(flash[:alert]).to eq("You don't have access to this road trip.")
      end
    end
  end

  describe "DELETE destroy" do
    let(:route) { create(:route, road_trip: road_trip, user: user) }
    let!(:waypoint1) { create(:waypoint, route: route, position: 1, latitude: 37.7749, longitude: -122.4194) }
    let!(:waypoint2) { create(:waypoint, route: route, position: 2, latitude: 37.7849, longitude: -122.4094) }
    let!(:waypoint3) { create(:waypoint, route: route, position: 3, latitude: 37.7949, longitude: -122.3994) }

    it "deletes the waypoint, reorders remaining waypoints, and recalculates route metrics" do
      # Mock the route calculator to return updated metrics
      calculator = instance_double(RouteDistanceCalculator)
      allow(RouteDistanceCalculator).to receive(:new).and_return(calculator)
      allow(calculator).to receive(:calculate).and_return({ distance: 300.0, duration: 5.5 })

      expect {
        delete :destroy, params: { id: waypoint2.id }, xhr: true
      }.to change(Waypoint, :count).by(-1)

      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response["status"]).to eq("success")
      expect(json_response["route_metrics"]["distance"]).to eq(300.0)
      expect(json_response["route_metrics"]["duration"]).to eq(5.5)

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
        delete :destroy, params: { id: other_waypoint.id }, xhr: true

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Access denied.")
      end
    end

    context "when waypoint doesn't exist" do
      it "returns not found status" do
        delete :destroy, params: { id: 999999 }, xhr: true

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Waypoint not found.")
      end
    end
  end

  describe "PATCH recalculate_route_metrics" do
    let(:route) { create(:route, road_trip: road_trip, user: user) }
    let!(:waypoint) { create(:waypoint, route: route, position: 1, latitude: 37.7749, longitude: -122.4194) }

    it "recalculates and returns updated route metrics" do
      # Mock the route calculator to return updated metrics
      calculator = instance_double(RouteDistanceCalculator)
      allow(RouteDistanceCalculator).to receive(:new)
        .with(route.starting_location, route.destination, [ waypoint ], avoid_motorways: false)
        .and_return(calculator)
      allow(calculator).to receive(:calculate).and_return({ distance: 450.0, duration: 7.0 })

      patch :recalculate_route_metrics, params: { id: waypoint.id }, xhr: true

      expect(response).to have_http_status(:success)

      json_response = JSON.parse(response.body)
      expect(json_response["status"]).to eq("success")
      expect(json_response["message"]).to eq("Route metrics recalculated successfully.")
      expect(json_response["route_metrics"]["distance"]).to eq(450.0)
      expect(json_response["route_metrics"]["duration"]).to eq(7.0)

      # Verify the route was actually updated in the database
      route.reload
      expect(route.distance).to eq(450.0)
      expect(route.duration).to eq(7.0)
    end

    context "when user doesn't have access to the route" do
      let(:other_user) { create(:user) }
      let(:other_road_trip) { create(:road_trip, user: other_user) }
      let(:other_route) { create(:route, road_trip: other_road_trip, user: other_user) }
      let(:other_waypoint) { create(:waypoint, route: other_route, position: 1) }

      it "returns forbidden status" do
        patch :recalculate_route_metrics, params: { id: other_waypoint.id }, xhr: true

        expect(response).to have_http_status(:forbidden)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Access denied.")
      end
    end

    context "when waypoint doesn't exist" do
      it "returns not found status" do
        patch :recalculate_route_metrics, params: { id: 999999 }, xhr: true

        expect(response).to have_http_status(:not_found)
        json_response = JSON.parse(response.body)
        expect(json_response["status"]).to eq("error")
        expect(json_response["message"]).to eq("Waypoint not found.")
      end
    end
  end
end
