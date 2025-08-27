require 'rails_helper'

RSpec.describe "Application", type: :request do
  describe "GET /" do
    it "returns a welcome message" do
      get "/"
      expect(response).to have_http_status(200)
      
      json = JSON.parse(response.body)
      expect(json["message"]).to eq("Welcome to Roadtrip Planner!")
      expect(json["status"]).to eq("Running")
      expect(json["timestamp"]).to be_present
    end
  end

  describe "GET /up" do
    it "returns health check" do
      get "/up"
      expect(response).to have_http_status(200)
    end
  end
end