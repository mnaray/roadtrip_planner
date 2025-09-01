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
    before { Route.delete_all }

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

      it 'is invalid when user does not match road trip user' do
        other_user = create(:user)
        route = build(:route, road_trip: road_trip, user: other_user)

        expect(route).not_to be_valid
        expect(route.errors[:user]).to include("must match the road trip's user")
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
      before { route.update_column(:distance, 150.5) }

      it 'returns the stored distance' do
        expect(route.distance_in_km).to eq(150.5)
      end
    end

    context 'when distance is not stored' do
      before { route.update_column(:distance, nil) }

      it 'calculates and saves the distance' do
        calculator = instance_double(RouteDistanceCalculator)
        allow(RouteDistanceCalculator).to receive(:new)
          .with(route.starting_location, route.destination)
          .and_return(calculator)
        allow(calculator).to receive(:calculate).and_return({ distance: 120.5, duration: 2.5 })

        expect(route.distance_in_km).to eq(120.5)
        expect(route.reload.distance).to eq(120.5)
      end
    end
  end

  describe 'distance calculation on save' do
    let(:user) { create(:user) }
    let(:road_trip) { create(:road_trip, user: user) }

    it 'calculates distance and duration when creating a new route' do
      calculator = instance_double(RouteDistanceCalculator)
      allow(RouteDistanceCalculator).to receive(:new)
        .with("New York", "Boston")
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
        .with("Chicago", route.destination)
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
  end
end
