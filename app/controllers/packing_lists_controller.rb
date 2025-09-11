class PackingListsController < ApplicationController
  before_action :require_login
  before_action :set_road_trip
  before_action :set_packing_list, only: [ :show, :edit, :update, :destroy ]

  def index
    @packing_lists = @road_trip.packing_lists.includes(:packing_list_items)
    render PackingLists::IndexComponent.new(road_trip: @road_trip, packing_lists: @packing_lists, current_user: current_user)
  end

  def show
    @packing_list_items = @packing_list.packing_list_items.includes(:packing_list)
    render PackingLists::ShowComponent.new(road_trip: @road_trip, packing_list: @packing_list, packing_list_items: @packing_list_items, current_user: current_user)
  end

  def new
    @packing_list = @road_trip.packing_lists.build
    render PackingLists::NewComponent.new(road_trip: @road_trip, packing_list: @packing_list, current_user: current_user)
  end

  def create
    @packing_list = @road_trip.packing_lists.build(packing_list_params)

    if @packing_list.save
      redirect_to [ @road_trip, @packing_list ], notice: "Packing list was successfully created."
    else
      render PackingLists::NewComponent.new(road_trip: @road_trip, packing_list: @packing_list, current_user: current_user), status: :unprocessable_entity
    end
  end

  def edit
    render PackingLists::EditComponent.new(road_trip: @road_trip, packing_list: @packing_list, current_user: current_user)
  end

  def update
    if @packing_list.update(packing_list_params)
      redirect_to [ @road_trip, @packing_list ], notice: "Packing list was successfully updated."
    else
      render PackingLists::EditComponent.new(road_trip: @road_trip, packing_list: @packing_list, current_user: current_user), status: :unprocessable_entity
    end
  end

  def destroy
    @packing_list.destroy!
    redirect_to [ @road_trip, :packing_lists ], notice: "Packing list was successfully deleted."
  end

  private

  def set_road_trip
    @road_trip = current_user.road_trips.find(params[:road_trip_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Road trip not found."
  end

  def set_packing_list
    @packing_list = @road_trip.packing_lists.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to [ @road_trip, :packing_lists ], alert: "Packing list not found."
  end

  def packing_list_params
    params.require(:packing_list).permit(:name)
  end
end
