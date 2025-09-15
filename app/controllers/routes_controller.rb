class RoutesController < ApplicationController
  before_action :require_login
  before_action :set_road_trip, only: [ :new, :create ]
  before_action :set_route, only: [ :show, :edit, :update, :destroy, :map, :export_gpx, :edit_waypoints, :update_waypoints ]
  before_action :set_road_trip_for_route, only: [ :edit, :update ]
  before_action :set_route_for_confirmation, only: [ :confirm_route, :approve_route ]

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
      "destination" => @route.destination,
      "avoid_motorways" => @route.avoid_motorways
    }

    if @route.valid?(:location_only)
      redirect_to set_waypoints_path
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

    road_trip = RoadTrip.find(route_data["road_trip_id"])

    # Check if user has access to this road trip
    unless road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this road trip."
      return
    end
    @route = road_trip.routes.build(
      starting_location: route_data["starting_location"],
      destination: route_data["destination"],
      datetime: params[:datetime],
      avoid_motorways: route_data["avoid_motorways"] || false,
      user: current_user
    )

    if @route.save
      # Create waypoints if they were provided in the session
      if route_data["waypoints"].present?
        route_data["waypoints"].each_with_index do |waypoint_data, index|
          @route.waypoints.create!(
            latitude: waypoint_data["latitude"],
            longitude: waypoint_data["longitude"],
            position: index + 1
          )
        end
      end

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

  def export_gpx
    gpx_generator = RouteGpxGenerator.new(@route)
    gpx_content = gpx_generator.generate

    filename = "route_#{@route.id}_#{@route.starting_location.parameterize}_to_#{@route.destination.parameterize}.gpx"

    send_data gpx_content,
              filename: filename,
              type: "application/gpx+xml",
              disposition: "attachment"
  end

  def edit_waypoints
    @waypoints = @route.waypoints.ordered
    render Routes::EditWaypointsComponent.new(route: @route, waypoints: @waypoints, current_user: current_user)
  end

  def update_waypoints
    # Handle waypoint updates
    if params[:waypoints].present?
      begin
        # Parse waypoints data
        waypoints_data = JSON.parse(params[:waypoints])

        # Delete existing waypoints
        @route.waypoints.destroy_all

        # Create new waypoints
        waypoints_data.each do |waypoint_data|
          @route.waypoints.create!(
            latitude: waypoint_data["latitude"],
            longitude: waypoint_data["longitude"],
            position: waypoint_data["position"],
            name: waypoint_data["name"]
          )
        end

        redirect_to @route.road_trip, notice: "Waypoints updated successfully."
      rescue => e
        Rails.logger.error "Failed to update waypoints: #{e.message}"
        redirect_to edit_route_waypoints_path(@route), alert: "Failed to update waypoints."
      end
    else
      # If no waypoints provided, just clear them
      @route.waypoints.destroy_all
      redirect_to @route.road_trip, notice: "All waypoints removed."
    end
  end

  private

  def set_road_trip
    @road_trip = RoadTrip.find(params[:road_trip_id])

    # Check if user has access (is owner or participant)
    unless @road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this road trip."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Road trip not found."
  end

  def set_route
    @route = Route.find(params[:id])

    # Check if user has access to the road trip containing this route
    unless @route.road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this route."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Route not found."
  end

  def set_road_trip_for_route
    @road_trip = @route.road_trip
  end

  def set_route_for_confirmation
    return if session[:route_data]
    redirect_to road_trips_path, alert: "No route data found."
  end

  def route_create_params
    params.require(:route).permit(:starting_location, :destination, :avoid_motorways)
  end

  def route_params
    params.require(:route).permit(:starting_location, :destination, :datetime, :avoid_motorways)
  end
end
