require 'rails_helper'

RSpec.describe "User Registration", type: :request do
  describe "POST /register" do
    context "with valid parameters" do
      let(:valid_attributes) do
        {
          user: {
            username: "testuser#{rand(1000)}",
            password: "password123",
            password_confirmation: "password123"
          }
        }
      end

      it "creates a new user" do
        expect {
          post "/register", params: valid_attributes
        }.to change(User, :count).by(1)
      end

      it "creates user with correct attributes" do
        test_username = "testuser#{rand(1000)}"
        test_attributes = {
          user: {
            username: test_username,
            password: "password123",
            password_confirmation: "password123"
          }
        }

        post "/register", params: test_attributes

        user = User.last
        expect(user.username).to eq(test_username.downcase)
        expect(user.authenticate("password123")).to be_truthy
      end

      it "redirects to root path after successful registration" do
        post "/register", params: valid_attributes
        expect(response).to redirect_to(root_path)
      end

      it "logs in the user after successful registration" do
        test_username = "testuser#{rand(1000)}"
        test_attributes = {
          user: {
            username: test_username,
            password: "password123",
            password_confirmation: "password123"
          }
        }

        post "/register", params: test_attributes

        follow_redirect!
        expect(response.body).to include("Welcome, #{test_username.downcase}!")
      end
    end

    context "with invalid parameters" do
      it "does not create a user with missing username" do
        invalid_attributes = {
          user: {
            username: "",
            password: "password123",
            password_confirmation: "password123"
          }
        }

        expect {
          post "/register", params: invalid_attributes
        }.not_to change(User, :count)
      end

      it "does not create a user with missing password" do
        invalid_attributes = {
          user: {
            username: "testuser",
            password: "",
            password_confirmation: ""
          }
        }

        expect {
          post "/register", params: invalid_attributes
        }.not_to change(User, :count)
      end

      it "does not create a user with mismatched password confirmation" do
        invalid_attributes = {
          user: {
            username: "testuser",
            password: "password123",
            password_confirmation: "different_password"
          }
        }

        expect {
          post "/register", params: invalid_attributes
        }.not_to change(User, :count)
      end

      it "renders the registration form again with errors" do
        invalid_attributes = {
          user: {
            username: "",
            password: "",
            password_confirmation: ""
          }
        }

        post "/register", params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_content)
        expect(response.body).to include("can't be blank")
      end

      it "does not create duplicate usernames" do
        create(:user, username: "existinguser")

        duplicate_attributes = {
          user: {
            username: "existinguser",
            password: "password123",
            password_confirmation: "password123"
          }
        }

        expect {
          post "/register", params: duplicate_attributes
        }.not_to change(User, :count)
      end
    end
  end

  describe "GET /register" do
    it "returns successful response" do
      get "/register"
      expect(response).to have_http_status(:success)
    end

    it "renders registration form" do
      get "/register"
      expect(response.body).to include("Sign Up")
      expect(response.body).to include("Username")
      expect(response.body).to include("Password")
    end
  end
end
