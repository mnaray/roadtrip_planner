class RoadTripsController < ApplicationController
  before_action :require_login
  before_action :set_road_trip, only: [ :show, :edit, :update, :destroy ]
  before_action :set_road_trip_for_leave, only: [ :leave ]
  before_action :ensure_owner, only: [ :edit, :update, :destroy ]

  def index
    @owned_road_trips = current_user.road_trips.includes(:routes)
    @participating_road_trips = current_user.participating_road_trips.includes(:routes)
    render RoadTrips::IndexComponent.new(
      owned_road_trips: @owned_road_trips,
      participating_road_trips: @participating_road_trips,
      current_user: current_user
    )
  end

  def show
    @routes = @road_trip.routes.ordered_by_datetime
    render RoadTrips::ShowComponent.new(road_trip: @road_trip, routes: @routes, current_user: current_user)
  end

  def new
    @road_trip = current_user.road_trips.build
    render RoadTrips::NewComponent.new(road_trip: @road_trip, current_user: current_user)
  end

  def create
    @road_trip = current_user.road_trips.build(road_trip_params)

    if @road_trip.save
      redirect_to @road_trip, notice: "Road trip was successfully created."
    else
      render RoadTrips::NewComponent.new(road_trip: @road_trip, current_user: current_user), status: :unprocessable_entity
    end
  end

  def edit
    render RoadTrips::EditComponent.new(road_trip: @road_trip, current_user: current_user)
  end

  def update
    if @road_trip.update(road_trip_params)
      redirect_to @road_trip, notice: "Road trip was successfully updated."
    else
      render RoadTrips::EditComponent.new(road_trip: @road_trip, current_user: current_user), status: :unprocessable_entity
    end
  end

  def destroy
    @road_trip.destroy!
    redirect_to road_trips_path, notice: "Road trip was successfully deleted."
  end

  def leave
    if @road_trip.participant?(current_user)
      @road_trip.remove_participant(current_user)
      redirect_to road_trips_path, notice: "You have left the road trip"
    else
      redirect_to road_trips_path, alert: "You are not a participant of this road trip"
    end
  end

  private

  def set_road_trip
    @road_trip = RoadTrip.find(params[:id])
    
    # Check if user has access (is owner or participant)
    unless @road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this road trip."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Road trip not found."
  end

  def set_road_trip_for_leave
    @road_trip = RoadTrip.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Road trip not found."
  end

  def ensure_owner
    unless @road_trip.owner?(current_user)
      redirect_to @road_trip, alert: "Only the owner can perform this action."
    end
  end

  def road_trip_params
    params.require(:road_trip).permit(:name)
  end
end
