require 'rails_helper'

RSpec.describe "Pages", type: :request do
  describe "GET /" do
    context "when user is not logged in" do
      it "returns successful response" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "displays Get Started and Sign In buttons" do
        get root_path
        expect(response.body).to include("Get Started")
        expect(response.body).to include("Sign In")
      end

      it "does not display Start Planning button" do
        get root_path
        expect(response.body).not_to include("Start Planning")
      end
    end

    context "when user is logged in" do
      let(:user) { create(:user) }

      before do
        post login_path, params: { username: user.username, password: user.password }
      end

      it "returns successful response" do
        get root_path
        expect(response).to have_http_status(:success)
      end

      it "displays welcome message with username" do
        get root_path
        expect(response.body).to include("Welcome back, #{user.username}!")
      end

      it "displays Start Planning button" do
        get root_path
        expect(response.body).to include("Start Planning")
      end

      it "Start Planning button links to new road trip page" do
        get root_path
        expect(response.body).to include(new_road_trip_path)
      end

      it "does not display Get Started or Sign In buttons" do
        get root_path
        expect(response.body).not_to include("Get Started")
        expect(response.body).not_to include("Sign In")
      end
    end
  end

  describe "Start Planning button functionality" do
    let(:user) { create(:user) }

    before do
      post login_path, params: { username: user.username, password: user.password }
    end

    it "clicking Start Planning redirects to new road trip page" do
      get root_path
      expect(response.body).to include('href="/road_trips/new"')

      # Verify the new road trip page is accessible
      get new_road_trip_path
      expect(response).to have_http_status(:success)
      expect(response.body).to include("Create New Road Trip")
    end

    it "new road trip page requires authentication" do
      delete logout_path # Log out first

      get new_road_trip_path
      expect(response).to redirect_to(login_path)
    end
  end

  describe "GET /about" do
    context "when user is not logged in" do
      it "returns successful response" do
        get about_path
        expect(response).to have_http_status(:success)
      end

      it "displays About page title" do
        get about_path
        expect(response.body).to include("About Roadtrip Planner")
      end

      it "displays non-technical description" do
        get about_path
        expect(response.body).to include("helps you organize and plan road trips")
      end

      it "displays main features list" do
        get about_path
        expect(response.body).to include("Create and manage multiple road trips")
        expect(response.body).to include("Share road trips with friends and family")
        expect(response.body).to include("Plan detailed routes with waypoints")
        expect(response.body).to include("Create packing lists organized by categories")
      end

      it "displays getting started steps for anonymous users" do
        get about_path
        expect(response.body).to include("Ready to start planning your next adventure?")
        expect(response.body).to include("Create a free account")
        expect(response.body).to include("Create your first road trip")
      end

      it "displays Get Started and Sign In buttons" do
        get about_path
        expect(response.body).to include("Get Started")
        expect(response.body).to include("Sign In")
      end

      it "does not display logged-in user content" do
        get about_path
        expect(response.body).not_to include("View My Road Trips")
        expect(response.body).not_to include("You're already signed in")
      end
    end

    context "when user is logged in" do
      let(:user) { create(:user) }

      before do
        post login_path, params: { username: user.username, password: user.password }
      end

      it "returns successful response" do
        get about_path
        expect(response).to have_http_status(:success)
      end

      it "displays About page title" do
        get about_path
        expect(response.body).to include("About Roadtrip Planner")
      end

      it "displays getting started steps for logged-in users" do
        get about_path
        expect(response.body).to include("You&#39;re already signed in! Here&#39;s how to start planning:")
        expect(response.body).to include("My Road Trips")
        expect(response.body).to include("Start adding destinations")
      end

      it "displays View My Road Trips button" do
        get about_path
        expect(response.body).to include("View My Road Trips")
        expect(response.body).to include(road_trips_path)
      end

      it "does not display Get Started and Sign In buttons" do
        get about_path
        expect(response.body).not_to include("Get Started")
        expect(response.body).not_to include("Sign In")
      end
    end
  end
end
