require 'rails_helper'

RSpec.describe Route, 'overlap validation', type: :model do
  let(:user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let(:base_time) { 1.day.from_now.beginning_of_hour }

  describe 'datetime overlap validation with duration' do
    context 'when an existing route has a duration' do
      let!(:existing_route) do
        route = create(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time,
          starting_location: "New York",
          destination: "Boston"
        )
        # Manually set duration to 3 hours for testing
        route.update_column(:duration, 3.0)
        route
      end

      it 'prevents creating a route that starts during the existing route' do
        # Existing route: 10:00 AM - 1:00 PM (3 hours)
        # New route trying to start at 11:00 AM (during the existing route)
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time + 1.hour
        )

        expect(new_route).not_to be_valid
        expect(new_route.errors[:datetime]).to include("overlaps with another route in this road trip")
      end

      it 'prevents creating a route that ends during the existing route' do
        # Existing route: 10:00 AM - 1:00 PM (3 hours)
        # New route with 2-hour duration trying to start at 8:30 AM (would end at 10:30 AM)
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time - 1.5.hours
        )
        new_route.update_column(:duration, 2.0) if new_route.save(validate: false)

        new_route_check = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time - 1.5.hours
        )

        expect(new_route_check).not_to be_valid
        expect(new_route_check.errors[:datetime]).to include("overlaps with another route in this road trip")
      end

      it 'prevents creating a route that completely overlaps the existing route' do
        # Existing route: 10:00 AM - 1:00 PM (3 hours)
        # New route trying to start at 9:00 AM with 5-hour duration (would cover entire existing route)
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time - 1.hour
        )

        expect(new_route).not_to be_valid
        expect(new_route.errors[:datetime]).to include("overlaps with another route in this road trip")
      end

      it 'allows creating a route that starts exactly when the existing route ends' do
        # Existing route: 10:00 AM - 1:00 PM (3 hours)
        # New route starting at 1:00 PM (exactly when existing ends)
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time + 3.hours
        )

        expect(new_route).to be_valid
      end

      it 'allows creating a route that ends exactly when the existing route starts' do
        # Existing route: 10:00 AM - 1:00 PM (3 hours)
        # New route with 2-hour duration starting at 8:00 AM (ends at 10:00 AM)
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time - 2.hours
        )
        # Set duration to 2 hours
        allow(new_route).to receive(:duration_hours).and_return(2.0)

        expect(new_route).to be_valid
      end

      it 'prevents creating a route that starts 1 minute before existing route ends' do
        # Existing route: 10:00 AM - 1:00 PM (3 hours)
        # New route trying to start at 12:59 PM (1 minute before existing ends)
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time + 3.hours - 1.minute
        )

        expect(new_route).not_to be_valid
        expect(new_route.errors[:datetime]).to include("overlaps with another route in this road trip")
      end
    end

    context 'with multiple existing routes' do
      let!(:morning_route) do
        route = create(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time,
          starting_location: "New York",
          destination: "Philadelphia"
        )
        route.update_column(:duration, 2.0) # 10:00 AM - 12:00 PM
        route
      end

      let!(:afternoon_route) do
        route = create(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time + 4.hours,
          starting_location: "Philadelphia",
          destination: "Washington DC"
        )
        route.update_column(:duration, 1.5) # 2:00 PM - 3:30 PM
        route
      end

      it 'allows creating a route in the gap between existing routes' do
        # Morning route: 10:00 AM - 12:00 PM
        # Afternoon route: 2:00 PM - 3:30 PM
        # New route: 12:00 PM - 2:00 PM (fits in the gap)
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time + 2.hours
        )
        allow(new_route).to receive(:duration_hours).and_return(2.0)

        expect(new_route).to be_valid
      end

      it 'prevents creating a route that would overlap both existing routes' do
        # Morning route: 10:00 AM - 12:00 PM
        # Afternoon route: 2:00 PM - 3:30 PM
        # New route trying: 11:00 AM with 4-hour duration (would overlap both)
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time + 1.hour
        )
        allow(new_route).to receive(:duration_hours).and_return(4.0)

        expect(new_route).not_to be_valid
        expect(new_route.errors[:datetime]).to include("overlaps with another route in this road trip")
      end
    end

    context 'when routes have nil duration' do
      let!(:existing_route) do
        route = create(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time
        )
        route.update_column(:duration, nil)
        route
      end

      it 'uses default 2-hour duration for validation when duration is nil' do
        # Existing route with nil duration should be treated as 2 hours
        # So 10:00 AM - 12:00 PM
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time + 1.hour # 11:00 AM
        )

        expect(new_route).not_to be_valid
        expect(new_route.errors[:datetime]).to include("overlaps with another route in this road trip")
      end

      it 'allows route after default duration period' do
        # Existing route with nil duration (treated as 2 hours): 10:00 AM - 12:00 PM
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time + 2.hours # 12:00 PM
        )

        expect(new_route).to be_valid
      end
    end

    context 'edge cases' do
      let!(:existing_route) do
        route = create(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time
        )
        route.update_column(:duration, 0.5) # 30-minute route
        route
      end

      it 'handles very short duration routes correctly' do
        # Existing route: 10:00 AM - 10:30 AM (30 minutes)
        # New route at 10:30 AM should be allowed
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time + 30.minutes
        )

        expect(new_route).to be_valid
      end

      it 'handles very long duration routes correctly' do
        existing_route.update_column(:duration, 8.0) # 8-hour route

        # Existing route: 10:00 AM - 6:00 PM (8 hours)
        # New route at 5:00 PM should not be allowed
        new_route = build(:route,
          road_trip: road_trip,
          user: user,
          datetime: base_time + 7.hours
        )

        expect(new_route).not_to be_valid
        expect(new_route.errors[:datetime]).to include("overlaps with another route in this road trip")
      end
    end
  end

  describe 'updating existing routes' do
    let!(:route1) do
      route = create(:route,
        road_trip: road_trip,
        user: user,
        datetime: base_time
      )
      route.update_column(:duration, 2.0)
      route
    end

    let!(:route2) do
      route = create(:route,
        road_trip: road_trip,
        user: user,
        datetime: base_time + 3.hours
      )
      route.update_column(:duration, 2.0)
      route
    end

    it 'allows updating a route without changing its datetime' do
      route1.destination = "New Destination"
      expect(route1).to be_valid
    end

    it 'prevents updating a route to overlap with another' do
      # Route1: 10:00 AM - 12:00 PM
      # Route2: 1:00 PM - 3:00 PM
      # Try to move Route1 to 12:30 PM (would overlap with Route2)
      route1.datetime = base_time + 2.5.hours

      expect(route1).not_to be_valid
      expect(route1.errors[:datetime]).to include("overlaps with another route in this road trip")
    end
  end
end
