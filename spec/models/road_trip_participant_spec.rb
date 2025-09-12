require 'rails_helper'

RSpec.describe RoadTripParticipant, type: :model do
  describe 'associations' do
    it 'belongs to road_trip' do
      expect(RoadTripParticipant.reflect_on_association(:road_trip).macro).to eq(:belongs_to)
    end

    it 'belongs to user' do
      expect(RoadTripParticipant.reflect_on_association(:user).macro).to eq(:belongs_to)
    end
  end

  describe 'database constraints' do
    let(:user) { create(:user) }
    let(:road_trip) { create(:road_trip) }

    it 'prevents duplicate user-road_trip combinations' do
      create(:road_trip_participant, user: user, road_trip: road_trip)
      
      expect {
        create(:road_trip_participant, user: user, road_trip: road_trip)
      }.to raise_error(ActiveRecord::RecordNotUnique)
    end
  end
end