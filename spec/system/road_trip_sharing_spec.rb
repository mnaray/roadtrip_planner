require 'rails_helper'

RSpec.describe 'Road Trip Sharing', type: :system do
  let(:owner) { create(:user, username: 'tripowner') }
  let(:participant) { create(:user, username: 'participant1') }
  let(:other_user) { create(:user, username: 'otheruser') }
  let(:road_trip) { create(:road_trip, user: owner, name: 'Awesome Adventure') }

  before do
    driven_by(:rack_test)
  end

  describe 'Adding participants' do
    before do
      login_as(owner)
      visit road_trip_path(road_trip)
    end

    it 'allows owner to add participants' do
      within('.participants') do
        expect(page).to have_content('Participants')
        expect(page).to have_content(owner.username)
        expect(page).to have_content('Owner')

        fill_in 'username', with: participant.username
        click_button 'Add User'
      end

      expect(page).to have_content("#{participant.username} has been added to the road trip")

      within('.participants') do
        expect(page).to have_content(participant.username)
        expect(page).to have_content('Participant')
      end
    end

    it 'shows error for non-existent user' do
      within('.participants') do
        fill_in 'username', with: 'nonexistent'
        click_button 'Add User'
      end

      expect(page).to have_content("User 'nonexistent' not found")
    end

    it 'prevents adding owner as participant' do
      within('.participants') do
        fill_in 'username', with: owner.username
        click_button 'Add User'
      end

      expect(page).to have_content('Cannot add the owner as a participant')
    end

    it 'prevents duplicate participants' do
      road_trip.participants << participant
      visit road_trip_path(road_trip)

      within('.participants') do
        fill_in 'username', with: participant.username
        click_button 'Add User'
      end

      expect(page).to have_content("#{participant.username} is already a participant")
    end
  end

  describe 'Removing participants' do
    before do
      road_trip.participants << participant
      login_as(owner)
      visit road_trip_path(road_trip)
    end

    it 'allows owner to remove participants' do
      within('.participants') do
        expect(page).to have_content(participant.username)
        click_button 'Remove'
      end

      expect(page).to have_content("#{participant.username} has been removed from the road trip")

      within('.participants') do
        expect(page).not_to have_content(participant.username)
      end
    end
  end

  describe 'Participant experience' do
    before do
      road_trip.participants << participant
    end

    it 'shows shared trips on participant index' do
      login_as(participant)
      visit road_trips_path

      expect(page).to have_content('Shared with Me')
      expect(page).to have_content(road_trip.name)
      expect(page).to have_content('Shared')
    end

    it 'allows participants to access shared road trips' do
      login_as(participant)
      visit road_trip_path(road_trip)

      expect(page).to have_content(road_trip.name)
      expect(page).to have_content('Participants')
      expect(page).not_to have_link('Edit')
    end

    it 'allows participants to leave road trip' do
      login_as(participant)
      visit road_trip_path(road_trip)

      within('.participants') do
        click_button 'Leave Road Trip'
      end

      expect(page).to have_current_path(road_trips_path)
      expect(page).to have_content('You have left the road trip')
    end
  end

  describe 'Access control' do
    it 'prevents non-participants from accessing private road trips' do
      login_as(other_user)
      visit road_trip_path(road_trip)

      expect(page).to have_current_path(road_trips_path)
      expect(page).to have_content("You don't have access to this road trip")
    end

    it 'prevents participants from editing road trips' do
      road_trip.participants << participant
      login_as(participant)
      visit edit_road_trip_path(road_trip)

      expect(page).to have_current_path(road_trip_path(road_trip))
      expect(page).to have_content('Only the owner can perform this action')
    end

    it 'prevents non-owners from adding participants' do
      road_trip.participants << participant
      login_as(participant)
      visit road_trip_path(road_trip)

      within('.participants') do
        expect(page).not_to have_content('Add Participant')
        expect(page).not_to have_field('username')
      end
    end
  end

  private

  def login_as(user)
    visit login_path
    fill_in 'Username', with: user.username
    fill_in 'Password', with: 'password123'
    click_button 'Sign In'
  end
end
