class RoutesController < ApplicationController
  before_action :require_login
  before_action :set_road_trip, only: [:new, :create]
  before_action :set_route, only: [:show, :edit, :update, :destroy, :map]
  before_action :set_route_for_confirmation, only: [:confirm_route, :approve_route]

  def new
    @route = @road_trip.routes.build
    session[:route_data] = nil
    render Routes::FormPageComponent.new(route: @route, road_trip: @road_trip, current_user: current_user)
  end

  def create
    @route = @road_trip.routes.build(route_create_params)
    @route.user = current_user

    session[:route_data] = {
      "road_trip_id" => @road_trip.id,
      "starting_location" => @route.starting_location,
      "destination" => @route.destination
    }

    if @route.valid?(:location_only)
      redirect_to confirm_route_path
    else
      render Routes::FormPageComponent.new(route: @route, road_trip: @road_trip, current_user: current_user), 
             status: :unprocessable_content
    end
  end

  def show
    render Routes::MapComponent.new(route: @route, current_user: current_user)
  end

  def edit
    render Routes::FormPageComponent.new(route: @route, road_trip: @route.road_trip, current_user: current_user)
  end

  def update
    if @route.update(route_params)
      redirect_to @route.road_trip, notice: "Route was successfully updated."
    else
      render Routes::FormPageComponent.new(route: @route, road_trip: @route.road_trip, current_user: current_user), 
             status: :unprocessable_content
    end
  end

  def destroy
    road_trip = @route.road_trip
    @route.destroy!
    redirect_to road_trip, notice: "Route was successfully deleted."
  end

  def confirm_route
    render Routes::ConfirmPageComponent.new(route_data: session[:route_data], current_user: current_user)
  end

  def approve_route
    route_data = session[:route_data]
    return redirect_to road_trips_path, alert: "No route data found." unless route_data

    road_trip = current_user.road_trips.find(route_data["road_trip_id"])
    @route = road_trip.routes.build(
      starting_location: route_data["starting_location"],
      destination: route_data["destination"],
      datetime: params[:datetime],
      user: current_user
    )

    if @route.save
      session[:route_data] = nil
      redirect_to road_trip, notice: "Route was successfully added to your road trip."
    else
      Rails.logger.error "Route validation failed: #{@route.errors.full_messages}"
      render Routes::ConfirmPageComponent.new(route_data: route_data, route: @route, current_user: current_user), 
             status: :unprocessable_content
    end
  end

  def map
    render Routes::MapComponent.new(route: @route, current_user: current_user)
  end

  private

  def set_road_trip
    @road_trip = current_user.road_trips.find(params[:road_trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Road trip not found."
  end

  def set_route
    @route = current_user.routes.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Route not found."
  end

  def set_route_for_confirmation
    return if session[:route_data]
    redirect_to road_trips_path, alert: "No route data found."
  end

  def route_create_params
    params.require(:route).permit(:starting_location, :destination)
  end

  def route_params
    params.require(:route).permit(:starting_location, :destination, :datetime)
  end
end
