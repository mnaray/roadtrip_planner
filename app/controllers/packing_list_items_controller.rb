class PackingListItemsController < ApplicationController
  before_action :require_login
  before_action :set_road_trip_and_packing_list
  before_action :set_packing_list_item, only: [ :show, :edit, :update, :destroy, :toggle_packed ]

  def index
    packing_list_items = safe_packing_list_items
    resources = safe_resources.merge(packing_list_items: packing_list_items)

    render PackingListItems::IndexComponent.new(**resources)
  end

  def show
    resources = safe_resources

    render PackingListItems::ShowComponent.new(**resources)
  end

  def new
    @packing_list_item = @packing_list.packing_list_items.build
    resources = safe_resources

    render PackingListItems::NewComponent.new(**resources)
  end

  def create
    @packing_list_item = @packing_list.packing_list_items.build(packing_list_item_params)

    if @packing_list_item.save
      redirect_to [ @road_trip, @packing_list ], notice: "Item was successfully added to packing list."
    else
      resources = safe_resources

      render PackingListItems::NewComponent.new(**resources), status: :unprocessable_entity
    end
  end

  def edit
    resources = safe_resources

    render PackingListItems::EditComponent.new(**resources)
  end

  def update
    if @packing_list_item.update(packing_list_item_params)
      redirect_to [ @road_trip, @packing_list ], notice: "Item was successfully updated."
    else
      resources = safe_resources

      render PackingListItems::EditComponent.new(**resources), status: :unprocessable_entity
    end
  end

  def destroy
    @packing_list_item.destroy!
    redirect_to [ @road_trip, @packing_list ], notice: "Item was successfully removed from packing list."
  end

  def toggle_packed
    @packing_list_item.toggle_packed!
    redirect_to [ @road_trip, @packing_list ], notice: "Item packing status updated."
  end

  private

  def set_road_trip_and_packing_list
    @road_trip = RoadTrip.find(params[:road_trip_id])

    # Check if user has access (is owner or participant)
    unless @road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this road trip."
      return
    end

    @packing_list = @road_trip.packing_lists.find(params[:packing_list_id])
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Road trip or packing list not found."
  end

  def set_packing_list_item
    @packing_list_item = @packing_list.packing_list_items.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to [ @road_trip, @packing_list ], alert: "Packing list item not found."
  end

  # Helper method to get safe resource references for rendering
  def safe_resources
    {
      road_trip: @road_trip,
      packing_list: @packing_list,
      packing_list_item: @packing_list_item,
      current_user: current_user
    }
  end

  # Safe method to get packing list items without parameter exposure
  def safe_packing_list_items
    packing_list = @packing_list
    packing_list.packing_list_items.order(:category, :name)
  end

  def packing_list_item_params
    params.require(:packing_list_item).permit(:name, :quantity, :category, :packed)
  end
end
