require 'rails_helper'

RSpec.describe "User Login", type: :request do
  let(:user) { create(:user, username: "testuser", password: "password123") }

  describe "GET /login" do
    it "returns successful response" do
      get "/login"
      expect(response).to have_http_status(:success)
    end

    it "renders login form" do
      get "/login"
      expect(response.body).to include("Sign in to your account")
      expect(response.body).to include("Username")
      expect(response.body).to include("Password")
    end

    it "includes autocomplete attributes for password managers" do
      get "/login"
      expect(response.body).to include('autocomplete="username"')
      expect(response.body).to include('autocomplete="current-password"')
    end
  end

  describe "POST /login" do
    context "with valid credentials" do
      it "redirects to root path after successful login" do
        post "/login", params: { username: user.username, password: "password123" }
        expect(response).to redirect_to(root_path)
      end

      it "sets user session" do
        post "/login", params: { username: user.username, password: "password123" }
        follow_redirect!
        expect(response.body).to include("Welcome, #{user.username}!")
      end
    end

    context "with invalid credentials" do
      it "renders login form again with error" do
        post "/login", params: { username: user.username, password: "wrongpassword" }
        expect(response).to have_http_status(:ok)
        expect(response.body).to include("Invalid username or password")
      end

      it "does not set user session" do
        post "/login", params: { username: user.username, password: "wrongpassword" }
        expect(session[:user_id]).to be_nil
      end
    end
  end
end
