class FuelEconomiesController < ApplicationController
  before_action :require_login
  before_action :set_route
  before_action :authorize_access!

  def show
    render FuelEconomies::ShowComponent.new(route: @route, current_user: current_user)
  end

  private

  def set_route
    @route = Route.find(params[:route_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Route not found."
  end

  def authorize_access!
    unless @route.road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this route."
    end
  end
end
