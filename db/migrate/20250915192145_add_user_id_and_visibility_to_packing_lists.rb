class AddUserIdAndVisibilityToPackingLists < ActiveRecord::Migration[8.0]
  def up
    # Add columns without constraints first
    add_reference :packing_lists, :user, null: true, foreign_key: true
    add_column :packing_lists, :visibility, :string, default: 'private', null: false

    # For existing packing lists, set the creator as the road trip owner
    # and visibility as private (which is already the default)
    execute <<-SQL
      UPDATE packing_lists
      SET user_id = (
        SELECT user_id
        FROM road_trips
        WHERE road_trips.id = packing_lists.road_trip_id
      )
      WHERE user_id IS NULL
    SQL

    # Now make user_id non-nullable
    change_column_null :packing_lists, :user_id, false
  end

  def down
    remove_reference :packing_lists, :user, foreign_key: true
    remove_column :packing_lists, :visibility
  end
end
