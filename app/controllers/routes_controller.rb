class RoutesController < ApplicationController
  before_action :set_trip
  before_action :set_route, only: [:show, :edit, :update, :destroy, :export_gpx]
  
  def show
    @stops = @route.ordered_stops
  end
  
  def new
    @route = @trip.routes.build
    @route.day_number = (@trip.routes.maximum(:day_number) || 0) + 1
  end
  
  def create
    @route = @trip.routes.build(route_params)
    
    if @route.save
      redirect_to [@trip, @route], notice: 'Route was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @route.update(route_params)
      redirect_to [@trip, @route], notice: 'Route was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @route.destroy
    redirect_to @trip, notice: 'Route was successfully deleted.'
  end
  
  def export_gpx
    respond_to do |format|
      format.gpx do
        send_data @route.to_gpx, 
                  filename: "#{@trip.name}_day_#{@route.day_number}.gpx",
                  type: 'application/gpx+xml',
                  disposition: 'attachment'
      end
    end
  end
  
  private
  
  def set_trip
    @trip = Trip.find(params[:trip_id])
  end
  
  def set_route
    @route = @trip.routes.find(params[:id])
  end
  
  def route_params
    params.require(:route).permit(:name, :day_number, :total_distance, :estimated_duration_minutes, :notes)
  end
end