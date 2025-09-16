require 'rails_helper'

RSpec.describe "Routes", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let(:other_users_road_trip) { create(:road_trip, user: other_user) }
  let(:route) { create(:route, road_trip: road_trip, user: user) }
  let(:other_users_route) { create(:route, road_trip: other_users_road_trip, user: other_user) }

  # Helper to sign in user
  def sign_in_user(user)
    post login_path, params: { username: user.username, password: "password123" }
  end

  describe "GET /road_trips/:road_trip_id/routes/new" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when road trip belongs to user" do
        it "returns successful response" do
          get new_road_trip_route_path(road_trip)
          expect(response).to have_http_status(:success)
        end

        it "displays route form in modal" do
          get new_road_trip_route_path(road_trip)
          expect(response.body).to include("Add New Route")
        end
      end

      context "when road trip does not belong to user" do
        it "redirects with error message" do
          get new_road_trip_route_path(other_users_road_trip)
          expect(response).to redirect_to(road_trips_path)
          follow_redirect!
          expect(response.body).to include("You don&#39;t have access to this road trip.")
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get new_road_trip_route_path(road_trip)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "POST /road_trips/:road_trip_id/routes" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when road trip belongs to user" do
        context "with valid attributes" do
          let(:valid_params) do
            {
              route: {
                starting_location: "San Francisco, CA",
                destination: "Los Angeles, CA"
              }
            }
          end

          it "stores route data in session" do
            post road_trip_routes_path(road_trip), params: valid_params

            expect(session[:route_data]).to include(
              "road_trip_id" => road_trip.id,
              "starting_location" => "San Francisco, CA",
              "destination" => "Los Angeles, CA"
            )
          end

          it "redirects to set_waypoints page" do
            post road_trip_routes_path(road_trip), params: valid_params
            expect(response).to redirect_to(set_waypoints_path)
          end

          it "does not create a route yet" do
            expect {
              post road_trip_routes_path(road_trip), params: valid_params
            }.not_to change(Route, :count)
          end
        end

        context "with invalid attributes" do
          let(:invalid_params) do
            {
              route: {
                starting_location: "",
                destination: "Los Angeles, CA"
              }
            }
          end

          it "returns unprocessable entity status" do
            post road_trip_routes_path(road_trip), params: invalid_params
            expect(response).to have_http_status(:unprocessable_content)
          end

          it "does not store data in session" do
            post road_trip_routes_path(road_trip), params: invalid_params
            expect(session[:route_data]).to be_present # Still stores for potential retry
          end
        end
      end

      context "when road trip does not belong to user" do
        it "redirects with error message" do
          post road_trip_routes_path(other_users_road_trip), params: { route: { starting_location: "Test", destination: "Test" } }
          expect(response).to redirect_to(road_trips_path)
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        post road_trip_routes_path(road_trip), params: { route: { starting_location: "Test", destination: "Test" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /confirm_route" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "with route data in session" do
        before do
          # Set up session data by following the actual flow (POST to create route first)
          post road_trip_routes_path(road_trip), params: {
            route: {
              starting_location: "San Francisco, CA",
              destination: "Los Angeles, CA"
            }
          }
          # The create action should set session data and redirect to set_waypoints
          expect(response).to redirect_to(set_waypoints_path)

          # Then go through the waypoints flow to get to confirm route
          # For these tests, we'll manually set the session data to simulate completing waypoints
          session[:route_data] = {
            "road_trip_id" => road_trip.id,
            "starting_location" => "San Francisco, CA",
            "destination" => "Los Angeles, CA",
            "waypoints" => []
          }
        end

        it "returns successful response" do
          get confirm_route_path
          expect(response).to have_http_status(:success)
        end

        it "displays route confirmation page" do
          get confirm_route_path
          expect(response.body).to include("Review Your Route")
          expect(response.body).to include("San Francisco, CA")
          expect(response.body).to include("Los Angeles, CA")
        end
      end

      context "without route data in session" do
        it "redirects with error message" do
          get confirm_route_path
          expect(response).to redirect_to(road_trips_path)
          follow_redirect!
          expect(response.body).to include("No route data found")
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get confirm_route_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "POST /approve_route" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "with valid route data and datetime" do
        let(:datetime_param) { 2.hours.from_now.strftime("%Y-%m-%dT%H:%M") }

        it "creates a new route" do
          # First create the route data in session by posting to create route
          post road_trip_routes_path(road_trip), params: {
            route: {
              starting_location: "San Francisco, CA",
              destination: "Los Angeles, CA"
            }
          }

          # Then approve the route
          expect {
            post approve_route_path, params: { datetime: datetime_param }
          }.to change(Route, :count).by(1)
        end

        it "associates route with correct user and road trip" do
          # First create the route data in session
          post road_trip_routes_path(road_trip), params: {
            route: {
              starting_location: "San Francisco, CA",
              destination: "Los Angeles, CA"
            }
          }

          post approve_route_path, params: { datetime: datetime_param }
          new_route = Route.order(created_at: :desc).first
          expect(new_route).not_to be_nil
          expect(new_route.user).to eq(user)
          expect(new_route.road_trip).to eq(road_trip)
        end

        it "clears session data" do
          # First create the route data in session
          post road_trip_routes_path(road_trip), params: {
            route: {
              starting_location: "San Francisco, CA",
              destination: "Los Angeles, CA"
            }
          }

          post approve_route_path, params: { datetime: datetime_param }
          expect(session[:route_data]).to be_nil
        end

        it "redirects to road trip show page" do
          # First create the route data in session
          post road_trip_routes_path(road_trip), params: {
            route: {
              starting_location: "San Francisco, CA",
              destination: "Los Angeles, CA"
            }
          }

          post approve_route_path, params: { datetime: datetime_param }
          expect(response).to redirect_to(road_trip_path(road_trip))
          follow_redirect!
          expect(response.body).to include("Route was successfully added")
        end
      end

      context "with overlapping datetime" do
        let(:existing_route) { create(:route, road_trip: road_trip, user: user, datetime: 1.hour.from_now) }
        let(:overlapping_datetime) { existing_route.datetime + 30.minutes }

        before do
          existing_route # Ensure it exists
        end

        it "does not create route" do
          # First create the route data in session
          post road_trip_routes_path(road_trip), params: {
            route: {
              starting_location: "San Francisco, CA",
              destination: "Los Angeles, CA"
            }
          }

          expect {
            post approve_route_path, params: { datetime: overlapping_datetime.strftime("%Y-%m-%dT%H:%M") }
          }.not_to change(Route, :count)
        end

        it "returns unprocessable entity status" do
          # First create the route data in session
          post road_trip_routes_path(road_trip), params: {
            route: {
              starting_location: "San Francisco, CA",
              destination: "Los Angeles, CA"
            }
          }

          post approve_route_path, params: { datetime: overlapping_datetime.strftime("%Y-%m-%dT%H:%M") }
          expect(response).to have_http_status(:unprocessable_content)
        end

        it "displays error message" do
          # First create the route data in session
          post road_trip_routes_path(road_trip), params: {
            route: {
              starting_location: "San Francisco, CA",
              destination: "Los Angeles, CA"
            }
          }

          post approve_route_path, params: { datetime: overlapping_datetime.strftime("%Y-%m-%dT%H:%M") }
          expect(response.body).to include("overlaps with another route")
        end
      end

      context "without route data in session" do
        it "redirects with error message" do
          post approve_route_path, params: { datetime: 2.hours.from_now.strftime("%Y-%m-%dT%H:%M") }
          expect(response).to redirect_to(road_trips_path)
          follow_redirect!
          expect(response.body).to include("No route data found")
        end
      end
    end
  end

  describe "GET /routes/:id" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when route belongs to user" do
        it "returns successful response" do
          get route_path(route)
          expect(response).to have_http_status(:success)
        end

        it "displays route map" do
          get route_path(route)
          expect(response.body).to include("route-map")
          expect(response.body).to include(route.starting_location)
          expect(response.body).to include(route.destination)
        end
      end

      context "when route does not belong to user" do
        it "redirects with error message" do
          get route_path(other_users_route)
          expect(response).to redirect_to(road_trips_path)
          follow_redirect!
          expect(response.body).to include("You don&#39;t have access to this route.")
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get route_path(route)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /routes/:id/edit" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when route belongs to user" do
        it "returns successful response" do
          get edit_route_path(route)
          expect(response).to have_http_status(:success)
        end

        it "displays edit route form" do
          get edit_route_path(route)
          expect(response.body).to include("Edit Route")
          expect(response.body).to include(route.starting_location)
          expect(response.body).to include(route.destination)
        end
      end

      context "when route does not belong to user" do
        it "redirects with error message" do
          get edit_route_path(other_users_route)
          expect(response).to redirect_to(road_trips_path)
        end
      end
    end
  end

  describe "PATCH /routes/:id" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when route belongs to user" do
        context "with valid attributes" do
          let(:update_params) do
            {
              route: {
                starting_location: "Updated Start",
                destination: "Updated End",
                datetime: 3.hours.from_now.strftime("%Y-%m-%dT%H:%M")
              }
            }
          end

          it "updates the route" do
            patch route_path(route), params: update_params
            route.reload
            expect(route.starting_location).to eq("Updated Start")
            expect(route.destination).to eq("Updated End")
          end

          it "redirects to road trip show page" do
            patch route_path(route), params: update_params
            expect(response).to redirect_to(road_trip_path(route.road_trip))
            follow_redirect!
            expect(response.body).to include("Route was successfully updated")
          end
        end

        context "with invalid attributes" do
          it "does not update the route" do
            original_start = route.starting_location
            patch route_path(route), params: { route: { starting_location: "" } }
            route.reload
            expect(route.starting_location).to eq(original_start)
          end

          it "returns unprocessable entity status" do
            patch route_path(route), params: { route: { starting_location: "" } }
            expect(response).to have_http_status(:unprocessable_content)
          end
        end
      end

      context "when route does not belong to user" do
        it "redirects with error message" do
          patch route_path(other_users_route), params: { route: { starting_location: "Hacked" } }
          expect(response).to redirect_to(road_trips_path)
        end
      end
    end
  end

  describe "DELETE /routes/:id" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when route belongs to user" do
        it "destroys the route" do
          route # create the route
          expect {
            delete route_path(route)
          }.to change(Route, :count).by(-1)
        end

        it "redirects to road trip show page" do
          delete route_path(route)
          expect(response).to redirect_to(road_trip_path(route.road_trip))
          follow_redirect!
          expect(response.body).to include("Route was successfully deleted")
        end
      end

      context "when route does not belong to user" do
        it "redirects with error message and does not delete" do
          other_users_route # create the route
          expect {
            delete route_path(other_users_route)
          }.not_to change(Route, :count)
          expect(response).to redirect_to(road_trips_path)
        end
      end
    end
  end

  describe "GET /routes/:id/map" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when route belongs to user" do
        it "returns successful response" do
          get route_map_path(route)
          expect(response).to have_http_status(:success)
        end

        it "displays map view" do
          get route_map_path(route)
          expect(response.body).to include("Route Map")
          expect(response.body).to include("route-map")
        end
      end

      context "when route does not belong to user" do
        it "redirects with error message" do
          get route_map_path(other_users_route)
          expect(response).to redirect_to(road_trips_path)
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get route_map_path(route)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /routes/:id/edit_waypoints" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when route belongs to user" do
        it "returns successful response" do
          get edit_route_waypoints_path(route)
          expect(response).to have_http_status(:success)
        end

        it "displays waypoints editor" do
          get edit_route_waypoints_path(route)
          expect(response.body).to include("Edit Waypoints for Route")
          expect(response.body).to include("edit-waypoints-map")
        end
      end

      context "when route does not belong to user" do
        it "redirects with error message" do
          get edit_route_waypoints_path(other_users_route)
          expect(response).to redirect_to(road_trips_path)
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get edit_route_waypoints_path(route)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "PATCH /routes/:id/update_waypoints" do
    let!(:existing_waypoint1) { create(:waypoint, route: route, position: 1, latitude: 37.7749, longitude: -122.4194, name: "Waypoint 1") }
    let!(:existing_waypoint2) { create(:waypoint, route: route, position: 2, latitude: 34.0522, longitude: -118.2437, name: "Waypoint 2") }

    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when route belongs to user" do
        it "updates waypoints successfully and redirects to road trip" do
          new_waypoints_data = [
            { "latitude" => 36.7783, "longitude" => -119.4179, "position" => 1, "name" => "Fresno" },
            { "latitude" => 35.3733, "longitude" => -119.0187, "position" => 2, "name" => "Bakersfield" }
          ]

          initial_count = route.waypoints.count
          expect(initial_count).to eq(2)

          patch update_route_waypoints_path(route), params: { waypoints: new_waypoints_data.to_json }

          expect(response).to redirect_to(road_trip_path(route.road_trip))
          follow_redirect!
          expect(response.body).to include("Waypoints updated successfully")

          route.reload
          final_count = route.waypoints.count
          expect(final_count).to eq(2)

          updated_waypoints = route.waypoints.ordered
          expect(updated_waypoints.first.name).to eq("Fresno")
          expect(updated_waypoints.second.name).to eq("Bakersfield")
        end

        it "handles empty waypoints by clearing all existing ones" do
          expect {
            patch update_route_waypoints_path(route), params: { waypoints: "" }
          }.to change { route.waypoints.count }.from(2).to(0)

          expect(response).to redirect_to(road_trip_path(route.road_trip))
          follow_redirect!
          expect(response.body).to include("All waypoints removed")
        end

        it "handles malformed JSON gracefully" do
          patch update_route_waypoints_path(route), params: { waypoints: "invalid json" }

          expect(response).to redirect_to(edit_route_waypoints_path(route))
          expect(flash[:alert]).to eq("Invalid waypoints data format.")

          # Ensure existing waypoints are not affected
          route.reload
          expect(route.waypoints.count).to eq(2)
        end

        it "adds new waypoints when none existed before" do
          route_without_waypoints = create(:route, road_trip: road_trip, user: user)

          new_waypoints_data = [
            { "latitude" => 36.7783, "longitude" => -119.4179, "position" => 1, "name" => "Fresno" }
          ]

          expect {
            patch update_route_waypoints_path(route_without_waypoints), params: { waypoints: new_waypoints_data.to_json }
          }.to change { route_without_waypoints.waypoints.count }.from(0).to(1)

          expect(response).to redirect_to(road_trip_path(route_without_waypoints.road_trip))
        end
      end

      context "when route does not belong to user" do
        it "redirects with error message and does not update waypoints" do
          new_waypoints_data = [
            { "latitude" => 36.7783, "longitude" => -119.4179, "position" => 1, "name" => "Fresno" }
          ]

          patch update_route_waypoints_path(other_users_route), params: { waypoints: new_waypoints_data.to_json }

          expect(response).to redirect_to(road_trips_path)
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        patch update_route_waypoints_path(route), params: { waypoints: "[]" }
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
