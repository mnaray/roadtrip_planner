class PackingList < ApplicationRecord
  belongs_to :road_trip
  has_many :packing_list_items, dependent: :destroy

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }

  def total_items_count
    packing_list_items.sum(:quantity)
  end

  def packed_items_count
    packing_list_items.where(packed: true).sum(:quantity)
  end

  def packing_progress
    return 0 if total_items_count == 0
    (packed_items_count.to_f / total_items_count * 100).round(1)
  end

  def items_by_category
    packing_list_items.group_by(&:category)
  end
end