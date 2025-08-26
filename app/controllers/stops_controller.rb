class StopsController < ApplicationController
  before_action :set_trip_and_route
  before_action :set_stop, only: [:show, :edit, :update, :destroy]
  
  def new
    @stop = @route.stops.build
  end
  
  def create
    @stop = @route.stops.build(stop_params)
    
    if @stop.save
      redirect_to [@trip, @route], notice: 'Stop was successfully added.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @stop.update(stop_params)
      redirect_to [@trip, @route], notice: 'Stop was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @stop.destroy
    redirect_to [@trip, @route], notice: 'Stop was successfully removed.'
  end
  
  private
  
  def set_trip_and_route
    @trip = Trip.find(params[:trip_id])
    @route = @trip.routes.find(params[:route_id])
  end
  
  def set_stop
    @stop = @route.stops.find(params[:id])
  end
  
  def stop_params
    params.require(:stop).permit(:name, :address, :latitude, :longitude, :order, :arrival_time, :departure_time, :notes)
  end
end