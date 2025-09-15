class AddAvoidMotorwaysToRoutes < ActiveRecord::Migration[8.0]
  def change
    add_column :routes, :avoid_motorways, :boolean, default: false, null: false
  end
end
