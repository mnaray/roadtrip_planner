class ParticipantsController < ApplicationController
  before_action :require_login
  before_action :load_road_trip
  before_action :authorize_owner!, only: [:create, :destroy]

  def create
    username = params[:username]&.downcase
    user = User.find_by(username: username)

    if user.nil?
      redirect_to @road_trip, alert: "User '#{params[:username]}' not found"
    elsif user == @road_trip.user
      redirect_to @road_trip, alert: "Cannot add the owner as a participant"
    elsif @road_trip.participants.include?(user)
      redirect_to @road_trip, alert: "#{user.username} is already a participant"
    elsif @road_trip.add_participant(user)
      redirect_to @road_trip, notice: "#{user.username} has been added to the road trip"
    else
      redirect_to @road_trip, alert: "Failed to add participant"
    end
  end

  def destroy
    participant = User.find(params[:id])
    
    if @road_trip.remove_participant(participant)
      redirect_to @road_trip, notice: "#{participant.username} has been removed from the road trip"
    else
      redirect_to @road_trip, alert: "Failed to remove participant"
    end
  end

  private

  def load_road_trip
    @road_trip = RoadTrip.find(params[:road_trip_id])
  end

  def authorize_owner!
    unless @road_trip.owner?(current_user)
      redirect_to @road_trip, alert: "Only the owner can manage participants"
    end
  end
end