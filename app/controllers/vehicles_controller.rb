class VehiclesController < ApplicationController
  before_action :require_login
  before_action :set_vehicle, only: [ :show, :edit, :update, :destroy, :set_default ]
  before_action :ensure_owner, only: [ :show, :edit, :update, :destroy, :set_default ]

  def index
    @vehicles = current_user.vehicles.order(:name)
    @default_vehicle = current_user.default_vehicle
    render Vehicles::IndexComponent.new(vehicles: @vehicles, default_vehicle: @default_vehicle, current_user: current_user)
  end

  def show
    render Vehicles::ShowComponent.new(vehicle: @vehicle, current_user: current_user)
  end

  def new
    @vehicle = current_user.vehicles.build
    # Set as default if it's the user's first vehicle
    @vehicle.is_default = !current_user.has_vehicles?
    render Vehicles::NewComponent.new(vehicle: @vehicle, current_user: current_user)
  end

  def create
    @vehicle = current_user.vehicles.build(vehicle_params)
    # Set as default if it's the user's first vehicle and no default was explicitly set
    if !vehicle_params.key?(:is_default) && !current_user.has_vehicles?
      @vehicle.is_default = true
    end

    if @vehicle.save
      redirect_to garage_path, notice: "#{@vehicle.display_name} was successfully added to your garage."
    else
      render Vehicles::NewComponent.new(vehicle: @vehicle, current_user: current_user), status: :unprocessable_entity
    end
  end

  def edit
    render Vehicles::EditComponent.new(vehicle: @vehicle, current_user: current_user)
  end

  def update
    if @vehicle.update(vehicle_params)
      redirect_to garage_path, notice: "#{@vehicle.display_name} was successfully updated."
    else
      render Vehicles::EditComponent.new(vehicle: @vehicle, current_user: current_user), status: :unprocessable_entity
    end
  end

  def destroy
    vehicle_name = @vehicle.display_name
    @vehicle.destroy!
    redirect_to garage_path, notice: "#{vehicle_name} was successfully removed from your garage."
  end

  def set_default
    # The model callback will handle removing default from other vehicles
    if @vehicle.update(is_default: true)
      redirect_to garage_path, notice: "#{@vehicle.display_name} is now your default vehicle."
    else
      redirect_to garage_path, alert: "Failed to set default vehicle."
    end
  end

  private

  def set_vehicle
    @vehicle = current_user.vehicles.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to garage_path, alert: "Vehicle not found."
  end

  def ensure_owner
    unless @vehicle.user == current_user
      redirect_to garage_path, alert: "You can only access your own vehicles."
    end
  end

  def vehicle_params
    params.require(:vehicle).permit(:name, :vehicle_type, :make_model, :image,
                                   :engine_volume_ccm, :horsepower, :torque,
                                   :fuel_consumption, :dry_weight, :wet_weight,
                                   :passenger_count, :load_capacity)
  end
end
