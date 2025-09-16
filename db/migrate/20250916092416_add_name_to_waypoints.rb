class AddNameToWaypoints < ActiveRecord::Migration[8.0]
  def change
    add_column :waypoints, :name, :string unless column_exists?(:waypoints, :name)
  end
end
