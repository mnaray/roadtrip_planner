class AddDistanceToRoutes < ActiveRecord::Migration[8.0]
  def change
    add_column :routes, :distance, :float
  end
end
