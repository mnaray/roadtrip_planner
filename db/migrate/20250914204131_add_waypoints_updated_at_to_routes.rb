class AddWaypointsUpdatedAtToRoutes < ActiveRecord::Migration[8.0]
  def change
    add_column :routes, :waypoints_updated_at, :datetime
  end
end
