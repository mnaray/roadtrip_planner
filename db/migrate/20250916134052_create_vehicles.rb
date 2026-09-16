class CreateVehicles < ActiveRecord::Migration[8.0]
  def change
    create_table :vehicles do |t|
      t.references :user, null: false, foreign_key: true
      t.string :name, null: false
      t.string :vehicle_type, null: false
      t.string :make_model
      t.integer :engine_volume_ccm
      t.integer :horsepower
      t.integer :torque
      t.decimal :fuel_consumption, precision: 8, scale: 2
      t.decimal :dry_weight, precision: 8, scale: 2
      t.decimal :wet_weight, precision: 8, scale: 2
      t.integer :passenger_count
      t.decimal :load_capacity, precision: 8, scale: 2
      t.boolean :is_default, default: false, null: false

      t.timestamps
    end

    add_index :vehicles, [ :user_id, :is_default ], where: "is_default = true", unique: true
  end
end
