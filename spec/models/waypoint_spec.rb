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

  describe "route metrics invalidation callbacks" do
    let(:route) { create(:route) }

    before do
      # Set initial state where route metrics are calculated
      route.update_columns(waypoints_updated_at: 1.hour.ago)
      expect(route.reload.waypoints_updated_at).not_to be_nil # Ensure it's set
    end

    describe "after_create" do
      it "invalidates route metrics when waypoint is created" do
        expect {
          create(:waypoint, route: route)
        }.to change { route.reload.waypoints_updated_at }.to(nil)
      end
    end

    describe "after_update" do
      let!(:waypoint) do
        # Create waypoint first, then set route state
        wp = create(:waypoint, route: route)
        route.update_columns(waypoints_updated_at: 1.hour.ago)  # Reset after waypoint creation
        expect(route.reload.waypoints_updated_at).not_to be_nil # Ensure it's set
        wp
      end

      context "when position changes" do
        it "invalidates route metrics" do
          expect {
            waypoint.update!(position: waypoint.position + 1)
          }.to change { route.reload.waypoints_updated_at }.to(nil)
        end
      end

      context "when coordinates change" do
        it "invalidates route metrics when latitude changes" do
          expect {
            waypoint.update!(latitude: waypoint.latitude + 1.0)
          }.to change { route.reload.waypoints_updated_at }.to(nil)
        end

        it "invalidates route metrics when longitude changes" do
          expect {
            waypoint.update!(longitude: waypoint.longitude + 1.0)
          }.to change { route.reload.waypoints_updated_at }.to(nil)
        end
      end

      context "when irrelevant attributes change" do
        it "does not invalidate route metrics for non-position/coordinate changes" do
          original_waypoints_updated_at = route.waypoints_updated_at

          # Touch the waypoint to update its updated_at timestamp
          # but don't change position or coordinates
          waypoint.touch

          expect(route.reload.waypoints_updated_at).to eq(original_waypoints_updated_at)
        end
      end
    end

    describe "after_destroy" do
      let!(:waypoint) do
        # Create waypoint first, then set route state
        wp = create(:waypoint, route: route)
        route.update_columns(waypoints_updated_at: 1.hour.ago)  # Reset after waypoint creation
        expect(route.reload.waypoints_updated_at).not_to be_nil # Ensure it's set
        wp
      end

      it "invalidates route metrics when waypoint is destroyed" do
        expect {
          waypoint.destroy!
        }.to change { route.reload.waypoints_updated_at }.to(nil)
      end
    end
  end

  describe "integration with route metrics" do
    let(:user) { create(:user) }
    let(:road_trip) { create(:road_trip, user: user) }
    let(:route) { create(:route, user: user, road_trip: road_trip) }

    it "triggers route recalculation when waypoint affects the route" do
      # Mock the calculator to simulate different results with waypoints
      calculator = instance_double(RouteDistanceCalculator)

      # Initially no waypoints
      expect(route.waypoints_updated_at).to be_nil

      # Create waypoint - this should invalidate route metrics
      waypoint = create(:waypoint, route: route)
      expect(route.reload.waypoints_updated_at).to be_nil

      # When route metrics are recalculated, they should include the waypoint
      allow(RouteDistanceCalculator).to receive(:new)
        .with(route.starting_location, route.destination, [ waypoint ])
        .and_return(calculator)
      allow(calculator).to receive(:calculate)
        .and_return({ distance: 250.0, duration: 4.5 })

      result = route.recalculate_metrics!

      expect(result[:distance]).to eq(250.0)
      expect(result[:duration]).to eq(4.5)
      expect(route.waypoints_updated_at).to be_present
    end

    it "affects route overlap validation through duration changes" do
      base_time = 1.day.from_now.beginning_of_hour

      # Create first route with standard 2-hour duration
      route1 = create(:route, road_trip: road_trip, user: user, datetime: base_time)
      route1.update_columns(duration: 2.0, waypoints_updated_at: Time.zone.parse('2025-01-15 10:00:00'))

      # Should be able to create non-overlapping route at 3 hours later
      route2 = build(:route, road_trip: road_trip, user: user, datetime: base_time + 3.hours)
      expect(route2).to be_valid

      # Add waypoint to first route - this invalidates metrics
      waypoint = create(:waypoint, route: route1)
      expect(route1.reload.waypoints_updated_at).to be_nil

      # Mock the recalculated duration to be longer due to waypoint
      allow(route1).to receive(:current_duration_hours).and_return(4.0)

      # Now the second route should overlap due to longer duration
      route2_overlap = build(:route, road_trip: road_trip, user: user, datetime: base_time + 3.hours)
      expect(route2_overlap).not_to be_valid
      expect(route2_overlap.errors[:datetime]).to include('overlaps with another route in this road trip')
    end
  end
end
