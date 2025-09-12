require 'rails_helper'
require 'cgi'

RSpec.describe "RoadTrips", type: :request do
  let(:user) { create(:user) }
  let(:other_user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let(:other_users_road_trip) { create(:road_trip, user: other_user) }

  # Helper to sign in user
  def sign_in_user(user)
    post login_path, params: { username: user.username, password: "password123" }
  end

  describe "GET /road_trips" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      it "returns successful response" do
        get road_trips_path
        expect(response).to have_http_status(:success)
      end

      it "displays user's owned and participating road trips" do
        owned_trip = create(:road_trip, user: user, name: "User's Owned Trip")
        shared_trip = create(:road_trip, user: other_user, name: "Shared Trip")
        private_trip = create(:road_trip, user: other_user, name: "Private Trip")
        
        # Add user as participant to shared_trip
        shared_trip.participants << user

        get road_trips_path

        # Should show owned and shared trips
        expect(response.body).to include(CGI.escapeHTML(owned_trip.name))
        expect(response.body).to include(CGI.escapeHTML(shared_trip.name))
        # Should not show private trip
        expect(response.body).not_to include(CGI.escapeHTML(private_trip.name))
        
        # Should show sections
        expect(response.body).to include("My Road Trips")
        expect(response.body).to include("Shared with Me")
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get road_trips_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /road_trips/:id" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when road trip belongs to user" do
        it "returns successful response" do
          get road_trip_path(road_trip)
          expect(response).to have_http_status(:success)
        end

        it "displays road trip with routes ordered by datetime" do
          route1 = create(:route, road_trip: road_trip, user: user, datetime: 5.hours.from_now)
          route2 = create(:route, road_trip: road_trip, user: user, datetime: 1.hour.from_now)

          get road_trip_path(road_trip)

          # Routes should be displayed in chronological order
          expect(response.body.index(route2.starting_location)).to be < response.body.index(route1.starting_location)
        end
      end

      context "when road trip does not belong to user and user is not a participant" do
        it "redirects with access denied message" do
          get road_trip_path(other_users_road_trip)
          expect(response).to redirect_to(road_trips_path)
          follow_redirect!
          expect(response.body).to include("You don't have access to this road trip")
        end
      end

      context "when user is a participant" do
        let(:shared_road_trip) { create(:road_trip, user: other_user) }
        
        before do
          shared_road_trip.participants << user
        end

        it "allows access to shared road trip" do
          get road_trip_path(shared_road_trip)
          expect(response).to have_http_status(:success)
        end

        it "does not show edit button for participants" do
          get road_trip_path(shared_road_trip)
          expect(response.body).not_to include('href="' + edit_road_trip_path(shared_road_trip) + '"')
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get road_trip_path(road_trip)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /road_trips/new" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      it "returns successful response" do
        get new_road_trip_path
        expect(response).to have_http_status(:success)
      end

      it "displays new road trip form" do
        get new_road_trip_path
        expect(response.body).to include("Create New Road Trip")
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get new_road_trip_path
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "POST /road_trips" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "with valid attributes" do
        it "creates a new road trip" do
          expect {
            post road_trips_path, params: { road_trip: { name: "Test Road Trip" } }
          }.to change(RoadTrip, :count).by(1)
        end

        it "associates road trip with current user" do
          post road_trips_path, params: { road_trip: { name: "Test Road Trip" } }
          expect(RoadTrip.last.user).to eq(user)
        end

        it "redirects to road trip show page" do
          post road_trips_path, params: { road_trip: { name: "Test Road Trip" } }
          expect(response).to redirect_to(road_trip_path(RoadTrip.last))
          follow_redirect!
          expect(response.body).to include("Road trip was successfully created")
        end
      end

      context "with invalid attributes" do
        it "does not create a road trip" do
          expect {
            post road_trips_path, params: { road_trip: { name: "" } }
          }.not_to change(RoadTrip, :count)
        end

        it "returns unprocessable entity status" do
          post road_trips_path, params: { road_trip: { name: "" } }
          expect(response).to have_http_status(:unprocessable_content)
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        post road_trips_path, params: { road_trip: { name: "Test Trip" } }
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "GET /road_trips/:id/edit" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when road trip belongs to user" do
        it "returns successful response" do
          get edit_road_trip_path(road_trip)
          expect(response).to have_http_status(:success)
        end
      end

      context "when road trip does not belong to user" do
        it "redirects with error message" do
          get edit_road_trip_path(other_users_road_trip)
          expect(response).to redirect_to(road_trips_path)
        end
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        get edit_road_trip_path(road_trip)
        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe "PATCH /road_trips/:id" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when road trip belongs to user" do
        context "with valid attributes" do
          it "updates the road trip" do
            patch road_trip_path(road_trip), params: { road_trip: { name: "Updated Name" } }
            road_trip.reload
            expect(road_trip.name).to eq("Updated Name")
          end

          it "redirects to road trip show page" do
            patch road_trip_path(road_trip), params: { road_trip: { name: "Updated Name" } }
            expect(response).to redirect_to(road_trip_path(road_trip))
            follow_redirect!
            expect(response.body).to include("Road trip was successfully updated")
          end
        end

        context "with invalid attributes" do
          it "does not update the road trip" do
            original_name = road_trip.name
            patch road_trip_path(road_trip), params: { road_trip: { name: "" } }
            road_trip.reload
            expect(road_trip.name).to eq(original_name)
          end

          it "returns unprocessable entity status" do
            patch road_trip_path(road_trip), params: { road_trip: { name: "" } }
            expect(response).to have_http_status(:unprocessable_content)
          end
        end
      end

      context "when road trip does not belong to user" do
        it "redirects with error message" do
          patch road_trip_path(other_users_road_trip), params: { road_trip: { name: "Hacked" } }
          expect(response).to redirect_to(road_trips_path)
        end
      end
    end
  end

  describe "DELETE /road_trips/:id" do
    context "when user is logged in" do
      before { sign_in_user(user) }

      context "when road trip belongs to user" do
        it "destroys the road trip" do
          road_trip # create the road trip
          expect {
            delete road_trip_path(road_trip)
          }.to change(RoadTrip, :count).by(-1)
        end

        it "destroys associated routes" do
          create(:route, road_trip: road_trip, user: user)
          expect {
            delete road_trip_path(road_trip)
          }.to change(Route, :count).by(-1)
        end

        it "redirects to road trips index" do
          delete road_trip_path(road_trip)
          expect(response).to redirect_to(road_trips_path)
          follow_redirect!
          expect(response.body).to include("Road trip was successfully deleted")
        end
      end

      context "when road trip does not belong to user" do
        it "redirects with owner-only error message and does not delete" do
          other_users_road_trip.participants << user # Add user as participant
          expect {
            delete road_trip_path(other_users_road_trip)
          }.not_to change(RoadTrip, :count)
          expect(response).to redirect_to(road_trip_path(other_users_road_trip))
          follow_redirect!
          expect(response.body).to include("Only the owner can perform this action")
        end
      end
    end
  end

  describe "DELETE /road_trips/:id/leave" do
    let(:shared_road_trip) { create(:road_trip, user: other_user) }

    context "when user is logged in and is a participant" do
      before do
        sign_in_user(user)
        shared_road_trip.participants << user
      end

      it "removes user from participants" do
        expect {
          delete leave_road_trip_path(shared_road_trip)
        }.to change { shared_road_trip.participants.count }.by(-1)
        
        expect(shared_road_trip.participants).not_to include(user)
      end

      it "redirects to road trips index with success message" do
        delete leave_road_trip_path(shared_road_trip)
        expect(response).to redirect_to(road_trips_path)
        follow_redirect!
        expect(response.body).to include("You have left the road trip")
      end
    end

    context "when user is not a participant" do
      before { sign_in_user(user) }

      it "shows error message" do
        delete leave_road_trip_path(shared_road_trip)
        expect(response).to redirect_to(road_trips_path)
        follow_redirect!
        expect(response.body).to include("You are not a participant of this road trip")
      end
    end

    context "when user is not logged in" do
      it "redirects to login" do
        delete leave_road_trip_path(shared_road_trip)
        expect(response).to redirect_to(login_path)
      end
    end
  end
end
