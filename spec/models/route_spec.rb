require 'rails_helper'

RSpec.describe Route, type: :model do
  describe 'associations' do
    it 'belongs to a road trip' do
      expect(Route.reflect_on_association(:road_trip).macro).to eq(:belongs_to)
    end

    it 'belongs to a user' do
      expect(Route.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'validations' do
    subject { build(:route) }

    it 'validates presence of starting_location' do
      subject.starting_location = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:starting_location]).to include("can't be blank")
    end

    it 'validates presence of destination' do
      subject.destination = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:destination]).to include("can't be blank")
    end

    it 'validates length of starting_location' do
      subject.starting_location = ""
      expect(subject).not_to be_valid
      expect(subject.errors[:starting_location]).to include("is too short (minimum is 1 character)")

      subject.starting_location = "a" * 201
      expect(subject).not_to be_valid
      expect(subject.errors[:starting_location]).to include("is too long (maximum is 200 characters)")
    end

    it 'validates length of destination' do
      subject.destination = ""
      expect(subject).not_to be_valid
      expect(subject.errors[:destination]).to include("is too short (minimum is 1 character)")

      subject.destination = "a" * 201
      expect(subject).not_to be_valid
      expect(subject.errors[:destination]).to include("is too long (maximum is 200 characters)")
    end

    context 'with full validation context' do
      it 'validates presence of datetime' do
        subject.datetime = nil
        expect(subject).not_to be_valid
        expect(subject.errors[:datetime]).to include("can't be blank")
      end
    end

    context 'with location_only validation context' do
      it 'does not require datetime' do
        subject.datetime = nil
        expect(subject.valid?(:location_only)).to be true
      end
    end
  end

  describe 'scopes' do
    before do
      # Delete waypoints first to avoid foreign key constraint violation
      Waypoint.delete_all
      Route.delete_all
    end

    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let(:road_trip1) { create(:road_trip, user: user1) }
    let(:road_trip2) { create(:road_trip, user: user2) }

    # Use different road trips to avoid overlap validation
    let!(:route1) { create(:route, user: user1, road_trip: road_trip1, datetime: 1.hour.from_now) }
    let!(:route2) { build(:route, user: user1, road_trip: road_trip1, datetime: 5.hours.from_now).tap { |r| r.save!(validate: false) } }
    let!(:route3) { create(:route, user: user2, road_trip: road_trip2, datetime: 3.hours.from_now) }

    describe '.for_user' do
      it 'returns only routes for the specified user' do
        expect(Route.for_user(user1)).to contain_exactly(route1, route2)
        expect(Route.for_user(user2)).to contain_exactly(route3)
      end
    end

    describe '.ordered_by_datetime' do
      it 'returns routes ordered by datetime' do
        expect(Route.ordered_by_datetime).to eq([ route1, route3, route2 ])
      end
    end
  end

  describe 'custom validations' do
    let(:user) { create(:user) }
    let(:road_trip) { create(:road_trip, user: user) }

    describe 'datetime_not_overlapping_with_other_routes' do
      let(:base_time) { 1.day.from_now.beginning_of_hour }

      context 'when routes do not overlap' do
        it 'allows non-overlapping routes' do
          # Create existing route: 10:00 AM - 12:00 PM (default 2h)
          existing = create(:route, road_trip: road_trip, user: user, datetime: base_time)
          existing.update_column(:duration, 2.0) # Ensure it uses 2 hours

          # New route: 1:00 PM - 3:00 PM (default 2h) - should not overlap
          new_route = build(:route, road_trip: road_trip, user: user, datetime: base_time + 3.hours)

          expect(new_route).to be_valid
        end
      end

      context 'when routes overlap' do
        before do
          route = create(:route, road_trip: road_trip, user: user, datetime: base_time)
          route.update_column(:duration, 2.0) # Ensure 2-hour duration
        end

        it 'prevents overlapping start times' do
          overlapping_route = build(:route, road_trip: road_trip, user: user, datetime: base_time + 1.hour)

          expect(overlapping_route).not_to be_valid
          expect(overlapping_route.errors[:datetime]).to include('overlaps with another route in this road trip')
        end

        it 'prevents routes that would end during another route' do
          overlapping_route = build(:route, road_trip: road_trip, user: user, datetime: base_time - 1.hour)

          expect(overlapping_route).not_to be_valid
          expect(overlapping_route.errors[:datetime]).to include('overlaps with another route in this road trip')
        end

        it 'allows routes in different road trips' do
          other_road_trip = create(:road_trip, user: user)
          non_overlapping_route = build(:route, road_trip: other_road_trip, user: user, datetime: base_time + 1.hour)

          expect(non_overlapping_route).to be_valid
        end
      end

      context 'when updating an existing route' do
        let!(:existing_route) do
          route = create(:route, road_trip: road_trip, user: user, datetime: base_time)
          route.update_column(:duration, 2.0) # Ensure 2-hour duration
          route
        end

        it 'allows updating the same route without overlap error' do
          existing_route.starting_location = "New Starting Location"

          expect(existing_route).to be_valid
        end

        it 'prevents updating to overlap with other routes' do
          # Create second route: 2:00 PM - 4:00 PM (default 2h)
          second_route = create(:route, road_trip: road_trip, user: user, datetime: base_time + 4.hours)
          second_route.update_column(:duration, 2.0)

          # Try to move existing route to 3:00 PM (would overlap: 3:00 PM - 5:00 PM vs 2:00 PM - 4:00 PM)
          existing_route.datetime = base_time + 5.hours

          expect(existing_route).not_to be_valid
          expect(existing_route.errors[:datetime]).to include('overlaps with another route in this road trip')
        end
      end
    end

    describe 'user_matches_road_trip_user' do
      it 'is valid when user matches road trip user' do
        route = build(:route, road_trip: road_trip, user: user)
        expect(route).to be_valid
      end

      it 'is invalid when user does not match road trip user and is not a participant' do
        other_user = create(:user)
        route = build(:route, road_trip: road_trip, user: other_user)

        expect(route).not_to be_valid
        expect(route.errors[:user]).to include("must be the road trip owner or a participant")
      end

      it 'is valid when user is a participant of the road trip' do
        participant_user = create(:user)
        road_trip.participants << participant_user
        route = build(:route, road_trip: road_trip, user: participant_user)

        expect(route).to be_valid
      end
    end
  end

  describe '#duration_hours' do
    let(:user) { create(:user) }
    let(:road_trip) { create(:road_trip, user: user) }
    let(:route) { create(:route, user: user, road_trip: road_trip) }

    context 'when duration is already stored' do
      before { route.update_column(:duration, 3.5) }

      it 'returns the stored duration' do
        expect(route.duration_hours).to eq(3.5)
      end
    end

    context 'when duration is not stored' do
      before { route.update_column(:duration, nil) }

      it 'returns default duration' do
        expect(route.duration_hours).to eq(2.0)
      end
    end

    context 'when no route data is available' do
      before { route.update_columns(duration: nil, distance: nil) }

      it 'returns default duration of 2 hours' do
        calculator = instance_double(RouteDistanceCalculator)
        allow(RouteDistanceCalculator).to receive(:new)
          .with(route.starting_location, route.destination)
          .and_return(calculator)
        allow(calculator).to receive(:calculate).and_return({ distance: nil, duration: nil })

        expect(route.duration_hours).to eq(2.0)
      end
    end
  end

  describe '#distance_in_km' do
    let(:user) { create(:user) }
    let(:road_trip) { create(:road_trip, user: user) }
    let(:route) { create(:route, user: user, road_trip: road_trip) }

    context 'when distance is already stored' do
      before { route.update_column(:distance, 150500) } # 150.5 km stored as meters

      it 'returns the stored distance' do
        expect(route.distance_in_km).to eq(150.5)
      end
    end

    context 'when distance is not stored' do
      before { route.update_column(:distance, nil) }

      it 'calculates and saves the distance' do
        calculator = instance_double(RouteDistanceCalculator)
        allow(RouteDistanceCalculator).to receive(:new)
          .with(route.starting_location, route.destination, [], avoid_motorways: false)
          .and_return(calculator)
        allow(calculator).to receive(:calculate).and_return({ distance: 120500, duration: 2.5 }) # 120.5 km in meters

        expect(route.distance_in_km).to eq(120.5)
        expect(route.reload.distance).to eq(120500) # Distance stored in meters
      end
    end
  end

  describe 'distance calculation on save' do
    let(:user) { create(:user) }
    let(:road_trip) { create(:road_trip, user: user) }

    it 'calculates distance and duration when creating a new route' do
      calculator = instance_double(RouteDistanceCalculator)
      allow(RouteDistanceCalculator).to receive(:new)
        .with("New York", "Boston", [], avoid_motorways: false)
        .and_return(calculator)
      allow(calculator).to receive(:calculate).and_return({ distance: 250.0, duration: 4.5 })

      route = Route.create!(
        starting_location: "New York",
        destination: "Boston",
        datetime: 1.hour.from_now,
        road_trip: road_trip,
        user: user
      )

      expect(route.distance).to eq(250.0)
      expect(route.duration).to eq(4.5)
    end

    it 'recalculates distance and duration when locations change' do
      route = create(:route, user: user, road_trip: road_trip)
      route.update_columns(distance: 100.0, duration: 2.0)

      calculator = instance_double(RouteDistanceCalculator)
      allow(RouteDistanceCalculator).to receive(:new)
        .with("Chicago", route.destination, [], avoid_motorways: false)
        .and_return(calculator)
      allow(calculator).to receive(:calculate).and_return({ distance: 300.0, duration: 5.5 })

      route.update!(starting_location: "Chicago")
      expect(route.distance).to eq(300.0)
      expect(route.duration).to eq(5.5)
    end

    it 'does not recalculate if locations do not change' do
      route = create(:route, user: user, road_trip: road_trip)
      route.update_columns(distance: 100.0, duration: 2.0)

      expect(RouteDistanceCalculator).not_to receive(:new)
      route.update!(datetime: 5.hours.from_now)
      expect(route.distance).to eq(100.0)
      expect(route.duration).to eq(2.0)
    end

    context 'with waypoints' do
      it 'includes waypoints when calculating route metrics' do
        route = create(:route, user: user, road_trip: road_trip)
        waypoint = create(:waypoint, route: route, latitude: 40.7128, longitude: -74.0060)

        calculator = instance_double(RouteDistanceCalculator)
        allow(RouteDistanceCalculator).to receive(:new).and_return(calculator)
        allow(calculator).to receive(:calculate).and_return({ distance: 400.0, duration: 6.0 })

        route.update!(starting_location: "Modified Location")

        expect(route.distance).to eq(400.0)
        expect(route.duration).to eq(6.0)
        expect(route.waypoints_updated_at).to be_present
      end
    end
  end

  describe 'waypoint-related functionality' do
    let(:user) { create(:user) }
    let(:road_trip) { create(:road_trip, user: user) }
    let(:route) { create(:route, user: user, road_trip: road_trip) }

    describe '#recalculate_metrics!' do
      it 'forces recalculation of route metrics' do
        calculator = instance_double(RouteDistanceCalculator)
        allow(RouteDistanceCalculator).to receive(:new)
          .with(route.starting_location, route.destination, [], avoid_motorways: false)
          .and_return(calculator)
        allow(calculator).to receive(:calculate).and_return({ distance: 500.0, duration: 7.5 })

        result = route.recalculate_metrics!

        expect(result[:distance]).to eq(500.0)
        expect(result[:duration]).to eq(7.5)
        expect(route.reload.distance).to eq(500.0)
        expect(route.reload.duration).to eq(7.5)
      end

      it 'includes waypoints in recalculation' do
        waypoint = create(:waypoint, route: route, latitude: 40.7128, longitude: -74.0060)

        calculator = instance_double(RouteDistanceCalculator)
        allow(RouteDistanceCalculator).to receive(:new)
          .with(route.starting_location, route.destination, [ waypoint ], avoid_motorways: false)
          .and_return(calculator)
        allow(calculator).to receive(:calculate).and_return({ distance: 600.0, duration: 8.5 })

        result = route.recalculate_metrics!

        expect(result[:distance]).to eq(600.0)
        expect(result[:duration]).to eq(8.5)
        expect(route.waypoints_updated_at).to be_present
      end
    end

    describe '#metrics_outdated?' do
      context 'without waypoints' do
        it 'returns false' do
          expect(route.metrics_outdated?).to be false
        end
      end

      context 'with waypoints' do
        let!(:waypoint) { create(:waypoint, route: route) }

        context 'when waypoints_updated_at is nil' do
          before { route.update_columns(waypoints_updated_at: nil) }

          it 'returns true' do
            expect(route.metrics_outdated?).to be true
          end
        end

        context 'when waypoint was updated after last calculation' do
          before do
            route.update_columns(waypoints_updated_at: 1.hour.ago)
            waypoint.touch # Update waypoint's updated_at timestamp
          end

          it 'returns true' do
            expect(route.metrics_outdated?).to be true
          end
        end

        context 'when waypoints_updated_at is current' do
          it 'returns false when waypoints_updated_at is newer than waypoint updates' do
            route.update_columns(waypoints_updated_at: 1.minute.from_now)
            expect(route.metrics_outdated?).to be false
          end
        end
      end
    end

    describe '#current_duration_hours' do
      context 'when metrics are up to date' do
        before { route.update_columns(duration: 3.5) }

        it 'returns stored duration without recalculation' do
          expect(route).not_to receive(:recalculate_metrics!)
          expect(route.current_duration_hours).to eq(3.5)
        end
      end

      context 'when metrics are outdated' do
        let!(:waypoint) { create(:waypoint, route: route) }

        before do
          route.update_columns(duration: 2.0, waypoints_updated_at: nil)
        end

        it 'triggers recalculation and returns updated duration' do
          calculator = instance_double(RouteDistanceCalculator)
          allow(RouteDistanceCalculator).to receive(:new)
            .with(route.starting_location, route.destination, [ waypoint ], avoid_motorways: false)
            .and_return(calculator)
          allow(calculator).to receive(:calculate).and_return({ distance: 400.0, duration: 5.0 })

          expect(route.current_duration_hours).to eq(5.0)
        end
      end
    end

    describe 'avoid_motorways functionality' do
      describe 'defaults' do
        it 'defaults avoid_motorways to false' do
          route = Route.new
          expect(route.avoid_motorways).to be false
        end

        it 'persists avoid_motorways setting from database' do
          route = create(:route, user: user, road_trip: road_trip, avoid_motorways: false)
          expect(route.reload.avoid_motorways).to be false
        end
      end

      describe 'recalculation on avoid_motorways change' do
        it 'recalculates route metrics when avoid_motorways changes' do
          route = create(:route, user: user, road_trip: road_trip, avoid_motorways: false)
          route.update_columns(distance: 100.0, duration: 2.0)

          calculator = instance_double(RouteDistanceCalculator)
          allow(RouteDistanceCalculator).to receive(:new)
            .with(route.starting_location, route.destination, [], avoid_motorways: true)
            .and_return(calculator)
          allow(calculator).to receive(:calculate).and_return({ distance: 120.0, duration: 2.5 })

          route.update!(avoid_motorways: true)

          expect(route.distance).to eq(120.0)
          expect(route.duration).to eq(2.5)
        end

        it 'passes avoid_motorways parameter to RouteDistanceCalculator' do
          route = create(:route, user: user, road_trip: road_trip, avoid_motorways: true)

          expect(RouteDistanceCalculator).to receive(:new)
            .with(route.starting_location, route.destination, [], avoid_motorways: true)
            .and_call_original

          route.send(:calculate_route_metrics)
        end

        it 'passes avoid_motorways parameter with waypoints' do
          route = create(:route, user: user, road_trip: road_trip, avoid_motorways: true)
          waypoint = create(:waypoint, route: route, latitude: 40.7128, longitude: -74.0060)

          expect(RouteDistanceCalculator).to receive(:new)
            .with(route.starting_location, route.destination, [ waypoint ], avoid_motorways: true)
            .and_call_original

          route.send(:calculate_route_metrics)
        end
      end
    end

    describe 'overlap validation with waypoint recalculation' do
      let(:base_time) { 1.day.from_now.beginning_of_hour }

      it 'uses current_duration_hours for overlap validation' do
        # Create a route with standard 2-hour duration initially
        route1 = create(:route, road_trip: road_trip, user: user, datetime: base_time)
        route1.update_columns(duration: 2.0, waypoints_updated_at: Time.zone.parse('2025-01-15 10:00:00'))

        # Should be able to create non-overlapping route at 3 hours later initially
        route2 = build(:route, road_trip: road_trip, user: user, datetime: base_time + 3.hours)
        expect(route2).to be_valid

        # Add waypoint to first route - this invalidates metrics by setting waypoints_updated_at to nil
        waypoint = create(:waypoint, route: route1)
        route1.reload

        # Mock the recalculation to return longer duration due to waypoint
        calculator = instance_double(RouteDistanceCalculator)
        allow(RouteDistanceCalculator).to receive(:new).and_return(calculator)
        allow(calculator).to receive(:calculate).and_return({ distance: 400.0, duration: 4.0 })

        # Now the same route should overlap due to longer duration after recalculation
        route2_overlap = build(:route, road_trip: road_trip, user: user, datetime: base_time + 3.hours)

        # The overlap check should trigger recalculation and use the updated (longer) duration
        expect(route2_overlap).not_to be_valid
        expect(route2_overlap.errors[:datetime]).to include('overlaps with another route in this road trip')
      end
    end
  end
end
