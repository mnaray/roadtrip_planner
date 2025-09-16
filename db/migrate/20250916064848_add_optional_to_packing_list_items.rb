class AddOptionalToPackingListItems < ActiveRecord::Migration[8.0]
  def change
    add_column :packing_list_items, :optional, :boolean, default: false, null: false
  end
end
