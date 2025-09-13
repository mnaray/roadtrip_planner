require 'rails_helper'

RSpec.describe Waypoint, type: :model do
  describe "associations" do
    it "belongs to route" do
      waypoint = build(:waypoint)
      expect(waypoint).to respond_to(:route)
      expect(waypoint.route).to be_a(Route)
    end
  end

  describe "validations" do
    let(:route) { create(:route) }

    it "validates presence of latitude" do
      waypoint = build(:waypoint, route: route, latitude: nil)
      expect(waypoint).to be_invalid
      expect(waypoint.errors[:latitude]).to include("can't be blank")
    end

    it "validates presence of longitude" do
      waypoint = build(:waypoint, route: route, longitude: nil)
      expect(waypoint).to be_invalid
      expect(waypoint.errors[:longitude]).to include("can't be blank")
    end

    it "validates presence of position" do
      # Skip the callback and directly test validation
      waypoint = build(:waypoint, route: route, position: nil)
      waypoint.define_singleton_method(:set_next_position) { } # Override callback
      waypoint.valid?
      expect(waypoint.errors[:position]).to include("can't be blank")
    end

    it "validates latitude is within valid range" do
      waypoint = build(:waypoint, route: route, latitude: -91)
      expect(waypoint).to be_invalid
      expect(waypoint.errors[:latitude]).to include("must be greater than or equal to -90")

      waypoint = build(:waypoint, route: route, latitude: 91)
      expect(waypoint).to be_invalid
      expect(waypoint.errors[:latitude]).to include("must be less than or equal to 90")

      waypoint = build(:waypoint, route: route, latitude: 45.0)
      expect(waypoint).to be_valid
    end

    it "validates longitude is within valid range" do
      waypoint = build(:waypoint, route: route, longitude: -181)
      expect(waypoint).to be_invalid
      expect(waypoint.errors[:longitude]).to include("must be greater than or equal to -180")

      waypoint = build(:waypoint, route: route, longitude: 181)
      expect(waypoint).to be_invalid
      expect(waypoint.errors[:longitude]).to include("must be less than or equal to 180")

      waypoint = build(:waypoint, route: route, longitude: -122.4)
      expect(waypoint).to be_valid
    end

    it "validates position is a positive integer" do
      waypoint = build(:waypoint, route: route, position: 0)
      expect(waypoint).to be_invalid
      expect(waypoint.errors[:position]).to include("must be greater than 0")

      waypoint = build(:waypoint, route: route, position: -1)
      expect(waypoint).to be_invalid
      expect(waypoint.errors[:position]).to include("must be greater than 0")

      waypoint = build(:waypoint, route: route, position: 1.5)
      expect(waypoint).to be_invalid
      expect(waypoint.errors[:position]).to include("must be an integer")

      waypoint = build(:waypoint, route: route, position: 1)
      expect(waypoint).to be_valid
    end

    it "validates position uniqueness within route" do
      create(:waypoint, :with_position, route: route, position: 1)

      duplicate_waypoint = build(:waypoint, :with_position, route: route, position: 1)
      expect(duplicate_waypoint).to be_invalid
      expect(duplicate_waypoint.errors[:position]).to include("has already been taken")

      different_route = create(:route)
      same_position_different_route = build(:waypoint, :with_position, route: different_route, position: 1)
      expect(same_position_different_route).to be_valid
    end
  end

  describe "scopes" do
    let(:route) { create(:route) }

    it "orders waypoints by position" do
      waypoint3 = create(:waypoint, :with_position, route: route, position: 3)
      waypoint1 = create(:waypoint, :with_position, route: route, position: 1)
      waypoint2 = create(:waypoint, :with_position, route: route, position: 2)

      expect(route.waypoints.ordered).to eq([ waypoint1, waypoint2, waypoint3 ])
    end
  end

  describe "callbacks" do
    let(:route) { create(:route) }

    it "sets next position automatically when not provided" do
      waypoint1 = create(:waypoint, :with_position, route: route, position: 1)
      waypoint2 = create(:waypoint, route: route)

      expect(waypoint2.position).to eq(2)

      waypoint3 = create(:waypoint, route: route)
      expect(waypoint3.position).to eq(3)
    end

    it "does not change position when explicitly provided" do
      create(:waypoint, :with_position, route: route, position: 5)
      waypoint2 = create(:waypoint, :with_position, route: route, position: 2)

      expect(waypoint2.position).to eq(2)
    end

    it "handles empty route correctly" do
      waypoint = create(:waypoint, route: route)
      expect(waypoint.position).to eq(1)
    end
  end
end
