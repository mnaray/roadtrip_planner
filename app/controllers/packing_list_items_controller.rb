class PackingListItemsController < ApplicationController
  before_action :require_login
  before_action :set_road_trip_and_packing_list
  before_action :set_packing_list_item, only: [:show, :edit, :update, :destroy, :toggle_packed]

  def index
    @packing_list_items = @packing_list.packing_list_items.order(:category, :name)
    render PackingListItems::IndexComponent.new(road_trip: @road_trip, packing_list: @packing_list, packing_list_items: @packing_list_items, current_user: current_user)
  end

  def show
    render PackingListItems::ShowComponent.new(road_trip: @road_trip, packing_list: @packing_list, packing_list_item: @packing_list_item, current_user: current_user)
  end

  def new
    @packing_list_item = @packing_list.packing_list_items.build
    render PackingListItems::NewComponent.new(road_trip: @road_trip, packing_list: @packing_list, packing_list_item: @packing_list_item, current_user: current_user)
  end

  def create
    @packing_list_item = @packing_list.packing_list_items.build(packing_list_item_params)

    if @packing_list_item.save
      redirect_to [@road_trip, @packing_list], notice: "Item was successfully added to packing list."
    else
      render PackingListItems::NewComponent.new(road_trip: @road_trip, packing_list: @packing_list, packing_list_item: @packing_list_item, current_user: current_user), status: :unprocessable_entity
    end
  end

  def edit
    render PackingListItems::EditComponent.new(road_trip: @road_trip, packing_list: @packing_list, packing_list_item: @packing_list_item, current_user: current_user)
  end

  def update
    if @packing_list_item.update(packing_list_item_params)
      redirect_to [@road_trip, @packing_list], notice: "Item was successfully updated."
    else
      render PackingListItems::EditComponent.new(road_trip: @road_trip, packing_list: @packing_list, packing_list_item: @packing_list_item, current_user: current_user), status: :unprocessable_entity
    end
  end

  def destroy
    @packing_list_item.destroy!
    redirect_to [@road_trip, @packing_list], notice: "Item was successfully removed from packing list."
  end

  def toggle_packed
    @packing_list_item.toggle_packed!
    redirect_to [@road_trip, @packing_list], notice: "Item packing status updated."
  end

  private

  def set_road_trip_and_packing_list
    @road_trip = current_user.road_trips.find(params[:road_trip_id])
    @packing_list = @road_trip.packing_lists.find(params[:packing_list_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Road trip or packing list not found."
  end

  def set_packing_list_item
    @packing_list_item = @packing_list.packing_list_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to [@road_trip, @packing_list], alert: "Packing list item not found."
  end

  def packing_list_item_params
    params.require(:packing_list_item).permit(:name, :quantity, :category, :packed)
  end
end