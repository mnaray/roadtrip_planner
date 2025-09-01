class RoadTripsController < ApplicationController
  before_action :require_login
  before_action :set_road_trip, only: [ :show, :edit, :update, :destroy ]

  def index
    @road_trips = current_user.road_trips.includes(:routes)
    render RoadTrips::IndexComponent.new(road_trips: @road_trips, current_user: current_user)
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

  private

  def set_road_trip
    @road_trip = current_user.road_trips.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Road trip not found."
  end

  def road_trip_params
    params.require(:road_trip).permit(:name)
  end
end
