require 'rails_helper'

RSpec.describe "About", type: :request do
  describe "GET /about" do
    context "when user is not logged in" do
      it "returns successful response" do
        get about_path
        expect(response).to have_http_status(:success)
      end

      it "displays about page title" do
        get about_path
        expect(response.body).to include("About Roadtrip Planner")
      end

      it "renders markdown content as HTML" do
        get about_path
        expect(response.body).to include("About Roadtrip Planner</h1>")
        expect(response.body).to include("What We Do")
        expect(response.body).to include("Key Features")
        expect(response.body).to include("Why Choose Roadtrip Planner")
      end

      it "includes proper styling classes for markdown content" do
        get about_path
        expect(response.body).to include("prose prose-lg prose-gray mx-auto markdown-content")
      end

      it "displays navigation with About link" do
        get about_path
        expect(response.body).to include('href="/about"')
        expect(response.body).to include(">About<")
      end

      it "displays login and sign up links in navigation" do
        get about_path
        expect(response.body).to include(">Login<")
        expect(response.body).to include(">Sign Up<")
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

      it "displays about page content" do
        get about_path
        expect(response.body).to include("About Roadtrip Planner")
        expect(response.body).to include("Key Features")
      end

      it "displays welcome message with username in navigation" do
        get about_path
        expect(response.body).to include("Welcome, #{user.username}!")
      end

      it "displays My Road Trips and Logout links" do
        get about_path
        expect(response.body).to include(">My Road Trips<")
        expect(response.body).to include(">Logout<")
      end

      it "does not display Login or Sign Up links" do
        get about_path
        expect(response.body).not_to include(">Login<")
        expect(response.body).not_to include(">Sign Up<")
      end
    end

    context "markdown rendering" do
      it "converts markdown headings to HTML" do
        get about_path
        expect(response.body).to include("<h2>")
        expect(response.body).to include("<h3>")
      end

      it "converts markdown lists to HTML" do
        get about_path
        expect(response.body).to include("<ul>")
        expect(response.body).to include("<li>")
      end

      it "converts markdown emphasis to HTML" do
        get about_path
        expect(response.body).to include("<strong>")
        expect(response.body).to include("<em>")
      end

      it "handles emoji in markdown content" do
        get about_path
        expect(response.body).to include("🚗")
        expect(response.body).to include("✨")
        expect(response.body).to include("🌍")
      end
    end
  end
end
