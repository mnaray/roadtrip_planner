class AddDurationToRoutes < ActiveRecord::Migration[8.0]
  def change
    add_column :routes, :duration, :float
  end
end
