class TripsController < ApplicationController
  before_action :set_trip, only: [:show, :edit, :update, :destroy]
  
  def index
    @trips = Trip.all.order(created_at: :desc)
  end
  
  def show
    @routes = @trip.routes.ordered.includes(:stops)
  end
  
  def new
    @trip = Trip.new
  end
  
  def create
    @trip = Trip.new(trip_params)
    
    if @trip.save
      redirect_to @trip, notice: 'Trip was successfully created.'
    else
      render :new, status: :unprocessable_entity
    end
  end
  
  def edit
  end
  
  def update
    if @trip.update(trip_params)
      redirect_to @trip, notice: 'Trip was successfully updated.'
    else
      render :edit, status: :unprocessable_entity
    end
  end
  
  def destroy
    @trip.destroy
    redirect_to trips_url, notice: 'Trip was successfully deleted.'
  end
  
  private
  
  def set_trip
    @trip = Trip.find(params[:id])
  end
  
  def trip_params
    params.require(:trip).permit(:name, :description, :start_date, :end_date)
  end
end