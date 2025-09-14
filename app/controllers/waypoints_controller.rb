class WaypointsController < ApplicationController
  before_action :require_login
  before_action :find_route_from_session, only: [ :set_waypoints, :create ]
  before_action :set_waypoint, only: [ :destroy ]

  def set_waypoints
    return redirect_to road_trips_path, alert: "No route data found." unless @route_data

    @road_trip = RoadTrip.find(@route_data["road_trip_id"])

    unless @road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this road trip."
      return
    end

    render Routes::WaypointsPageComponent.new(route_data: @route_data, current_user: current_user)
  end

  def create
    return redirect_to road_trips_path, alert: "No route data found." unless @route_data

    road_trip = RoadTrip.find(@route_data["road_trip_id"])

    unless road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this road trip."
      return
    end

    # Parse waypoints data if it's provided (can be JSON string or array)
    waypoints_data = if params[:waypoints].present?
                       if params[:waypoints].is_a?(String)
                         JSON.parse(params[:waypoints])
                       else
                         params[:waypoints]
                       end
                     else
                       []
                     end

    session[:route_data] = @route_data.merge("waypoints" => waypoints_data)

    redirect_to confirm_route_path
  end

  def destroy
    if @waypoint.route.road_trip.can_access?(current_user)
      route_id = @waypoint.route.id
      position = @waypoint.position

      @waypoint.destroy!

      @waypoint.route.waypoints.where("position > ?", position).update_all("position = position - 1")

      render json: { status: "success", message: "Waypoint removed successfully." }
    else
      render json: { status: "error", message: "Access denied." }, status: :forbidden
    end
  end

  private

  def find_route_from_session
    @route_data = session[:route_data]
  end

  def set_waypoint
    @waypoint = Waypoint.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    render json: { status: "error", message: "Waypoint not found." }, status: :not_found
  end

  def waypoint_params
    params.require(:waypoint).permit(:latitude, :longitude, :position)
  end
end
