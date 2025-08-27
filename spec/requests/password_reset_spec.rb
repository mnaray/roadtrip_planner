require 'rails_helper'

RSpec.describe "Password Reset Functionality", type: :request do
  before do
    host! 'localhost:3000'
  end
  describe "Password reset routes" do
    it "does not have password reset routes defined" do
      # Check that common password reset routes return 404 or routing errors
      get "/passwords/new"
      expect(response.status).to eq(404).or eq(403)
      
      post "/passwords"
      expect(response.status).to eq(404).or eq(403)
      
      get "/passwords/edit" 
      expect(response.status).to eq(404).or eq(403)
      
      patch "/passwords/1"
      expect(response.status).to eq(404).or eq(403)
      
      get "/forgot_password"
      expect(response.status).to eq(404).or eq(403)
      
      post "/reset_password"
      expect(response.status).to eq(404).or eq(403)
    end
  end

  describe "User model" do
    let(:user) { create(:user) }

    it "does not have password reset token attributes" do
      expect(user).not_to respond_to(:reset_password_token)
      expect(user).not_to respond_to(:reset_password_sent_at)
      expect(user).not_to respond_to(:reset_password_digest)
    end

    it "does not have password reset methods" do
      expect(user).not_to respond_to(:generate_password_reset_token)
      expect(user).not_to respond_to(:send_password_reset_email)
      expect(user).not_to respond_to(:password_reset_expired?)
      expect(user).not_to respond_to(:reset_password!)
    end
  end

  describe "Controllers" do
    it "does not have PasswordResetsController" do
      expect { "PasswordResetsController".constantize }.to raise_error(NameError)
    end

    it "does not have PasswordsController" do
      expect { "PasswordsController".constantize }.to raise_error(NameError)
    end
  end

  describe "Application routes" do
    it "does not include password reset related routes" do
      routes_output = Rails.application.routes.routes.map(&:path).map(&:spec).join("\n")
      
      expect(routes_output).not_to include("password")
      expect(routes_output).not_to include("reset")
      expect(routes_output).not_to include("forgot")
    end
  end
end