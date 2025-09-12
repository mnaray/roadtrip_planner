require 'rails_helper'

RSpec.describe ParticipantsController, type: :request do
  let(:owner) { create(:user) }
  let(:participant) { create(:user) }
  let(:other_user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: owner) }

  # Helper to sign in user
  def sign_in_user(user)
    post login_path, params: { username: user.username, password: "password123" }
  end

  describe 'POST /road_trips/:road_trip_id/participants' do
    context 'when user is the owner' do
      before do
        sign_in_user(owner)
      end
      it 'adds a participant successfully' do
        post road_trip_participants_path(road_trip), params: { username: participant.username }

        expect(response).to redirect_to(road_trip_participants_path(road_trip))
        expect(flash[:notice]).to eq("#{participant.username} has been added to the road trip")
        expect(road_trip.reload.participants).to include(participant)
      end

      it 'handles case insensitive usernames' do
        post road_trip_participants_path(road_trip), params: { username: participant.username.upcase }

        expect(response).to redirect_to(road_trip_participants_path(road_trip))
        expect(road_trip.reload.participants).to include(participant)
      end

      it 'shows error for non-existent user' do
        post road_trip_participants_path(road_trip), params: { username: 'nonexistent' }

        expect(response).to redirect_to(road_trip_participants_path(road_trip))
        expect(flash[:alert]).to eq("User 'nonexistent' not found")
      end

      it 'prevents adding owner as participant' do
        post road_trip_participants_path(road_trip), params: { username: owner.username }

        expect(response).to redirect_to(road_trip_participants_path(road_trip))
        expect(flash[:alert]).to eq("Cannot add the owner as a participant")
        expect(road_trip.reload.participants).not_to include(owner)
      end

      it 'prevents duplicate participants' do
        road_trip.participants << participant

        post road_trip_participants_path(road_trip), params: { username: participant.username }

        expect(response).to redirect_to(road_trip_participants_path(road_trip))
        expect(flash[:alert]).to eq("#{participant.username} is already a participant")
      end
    end

    context 'when user is not the owner' do
      before do
        # Make sure participant is a participant but not the owner
        road_trip.participants << participant unless road_trip.participants.include?(participant)
        sign_in_user(participant)
      end

      it 'denies access' do
        post road_trip_participants_path(road_trip), params: { username: other_user.username }

        expect(response).to redirect_to(road_trip)
        follow_redirect!
        expect(response.body).to include("Only the owner can manage participants")
      end
    end

    context 'when user is not logged in' do
      before { delete logout_path }

      it 'redirects to login' do
        post road_trip_participants_path(road_trip), params: { username: participant.username }

        expect(response).to redirect_to(login_path)
      end
    end
  end

  describe 'DELETE /road_trips/:road_trip_id/participants/:id' do
    before do
      road_trip.participants << participant
    end

    context 'when user is the owner' do
      before do
        sign_in_user(owner)
      end

      it 'removes participant successfully' do
        delete road_trip_participant_path(road_trip, participant)

        expect(response).to redirect_to(road_trip_participants_path(road_trip))
        expect(flash[:notice]).to eq("#{participant.username} has been removed from the road trip")
        expect(road_trip.reload.participants).not_to include(participant)
      end
    end

    context 'when user is not the owner' do
      before do
        # Ensure participant has access to the road trip but is not the owner
        road_trip.participants << participant unless road_trip.participants.include?(participant)
        sign_in_user(participant)
      end

      it 'denies access' do
        delete road_trip_participant_path(road_trip, participant)

        expect(response).to redirect_to(road_trip)
        follow_redirect!
        expect(response.body).to include("Only the owner can manage participants")
      end
    end
  end
end
