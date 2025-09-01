require 'rails_helper'

RSpec.describe RoadTrip, type: :model do
  describe 'associations' do
    it 'belongs to a user' do
      expect(RoadTrip.reflect_on_association(:user).macro).to eq(:belongs_to)
    end

    it 'has many routes with dependent destroy' do
      expect(RoadTrip.reflect_on_association(:routes).macro).to eq(:has_many)
      expect(RoadTrip.reflect_on_association(:routes).options[:dependent]).to eq(:destroy)
    end
  end

  describe 'validations' do
    subject { build(:road_trip) }

    it 'validates presence of name' do
      subject.name = nil
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("can't be blank")
    end

    it 'validates length of name' do
      subject.name = ""
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("is too short (minimum is 1 character)")

      subject.name = "a" * 101
      expect(subject).not_to be_valid
      expect(subject.errors[:name]).to include("is too long (maximum is 100 characters)")

      subject.name = "Valid Name"
      expect(subject).to be_valid
    end
  end

  describe 'scopes' do
    let(:user1) { create(:user) }
    let(:user2) { create(:user) }
    let!(:road_trip1) { create(:road_trip, user: user1) }
    let!(:road_trip2) { create(:road_trip, user: user2) }

    describe '.for_user' do
      it 'returns only road trips for the specified user' do
        expect(RoadTrip.for_user(user1)).to contain_exactly(road_trip1)
        expect(RoadTrip.for_user(user2)).to contain_exactly(road_trip2)
      end
    end
  end

  describe '#day_count' do
    let(:road_trip) { create(:road_trip) }

    context 'with no routes' do
      it 'returns 0' do
        expect(road_trip.day_count).to eq(0)
      end
    end

    context 'with one route' do
      before do
        create(:route, road_trip: road_trip, user: road_trip.user)
      end

      it 'returns 1' do
        expect(road_trip.day_count).to eq(1)
      end
    end

    context 'with routes spanning multiple days' do
      let(:start_time) { Time.current.beginning_of_day }

      before do
        create(:route, road_trip: road_trip, user: road_trip.user, datetime: start_time)
        create(:route, road_trip: road_trip, user: road_trip.user, datetime: start_time + 1.day)
        create(:route, road_trip: road_trip, user: road_trip.user, datetime: start_time + 3.days)
      end

      it 'returns the correct day span' do
        expect(road_trip.day_count).to eq(4) # Day 0, 1, and 3 = 4 days total
      end
    end

    context 'with routes on the same day' do
      let(:start_time) { Time.current.beginning_of_day }

      before do
        create(:route, road_trip: road_trip, user: road_trip.user, datetime: start_time + 8.hours)
        create(:route, road_trip: road_trip, user: road_trip.user, datetime: start_time + 14.hours)
      end

      it 'returns 1' do
        expect(road_trip.day_count).to eq(1)
      end
    end
  end

  describe '#total_distance' do
    let(:road_trip) { create(:road_trip) }

    it 'returns the sum of all route distances' do
      route1 = create(:route, road_trip: road_trip, user: road_trip.user, datetime: 1.hour.from_now)
      route2 = create(:route, road_trip: road_trip, user: road_trip.user, datetime: 4.hours.from_now)
      route3 = create(:route, road_trip: road_trip, user: road_trip.user, datetime: 7.hours.from_now)
      
      # Mock the distance values
      allow(route1).to receive(:distance_in_km).and_return(120.5)
      allow(route2).to receive(:distance_in_km).and_return(85.3)
      allow(route3).to receive(:distance_in_km).and_return(200.7)
      
      # Need to reload to get the mocked routes
      allow(road_trip).to receive(:routes).and_return([route1, route2, route3])
      
      expect(road_trip.total_distance).to eq(406.5)
    end

    it 'returns 0.0 for no routes' do
      expect(road_trip.total_distance).to eq(0.0)
    end
    
    it 'handles nil distances gracefully' do
      route = create(:route, road_trip: road_trip, user: road_trip.user, datetime: 1.hour.from_now)
      allow(route).to receive(:distance_in_km).and_return(nil)
      allow(road_trip).to receive(:routes).and_return([route])
      
      expect(road_trip.total_distance).to eq(0.0)
    end
  end
end
