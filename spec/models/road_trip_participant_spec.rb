require 'rails_helper'

RSpec.describe RoadTripParticipant, type: :model do
  describe 'associations' do
    it { should belong_to(:road_trip) }
    it { should belong_to(:user) }
  end

  describe 'database constraints' do
    let(:user) { create(:user) }
    let(:road_trip) { create(:road_trip) }

    it 'prevents duplicate user-road_trip combinations' do
      create(:road_trip_participant, user: user, road_trip: road_trip)
      
      duplicate_participant = build(:road_trip_participant, user: user, road_trip: road_trip)
      expect(duplicate_participant).not_to be_valid
    end
  end
end