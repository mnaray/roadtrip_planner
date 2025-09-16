class PackingListItem < ApplicationRecord
  belongs_to :packing_list

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :quantity, presence: true, numericality: { greater_than: 0, only_integer: true }
  validates :category, presence: true
  validates :packed, inclusion: { in: [ true, false ] }
  validates :optional, inclusion: { in: [ true, false ] }

  enum :category, {
    tools: "tools",
    clothes: "clothes",
    hygiene: "hygiene",
    electronics: "electronics",
    food: "food",
    documents: "documents",
    medicine: "medicine",
    entertainment: "entertainment",
    other: "other"
  }

  scope :packed, -> { where(packed: true) }
  scope :unpacked, -> { where(packed: false) }
  scope :optional_items, -> { where(optional: true) }
  scope :required_items, -> { where(optional: false) }
  scope :by_category, ->(cat) { where(category: cat) }

  def toggle_packed!
    update!(packed: !packed)
  end
end
