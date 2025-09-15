class PackingList < ApplicationRecord
  belongs_to :road_trip
  belongs_to :user
  has_many :packing_list_items, dependent: :destroy

  validates :name, presence: true, length: { minimum: 1, maximum: 100 }
  validates :visibility, presence: true, inclusion: { in: %w[private public] }

  # Scopes for visibility
  scope :visible_to_user, ->(user) {
    where(
      "(visibility = 'public') OR (visibility = 'private' AND user_id = ?)",
      user.id
    )
  }
  scope :public_lists, -> { where(visibility: "public") }
  scope :private_lists, -> { where(visibility: "private") }

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

  # Visibility and ownership methods
  def private?
    visibility == "private"
  end

  def public?
    visibility == "public"
  end

  def owned_by?(check_user)
    user == check_user
  end

  def visible_to?(check_user)
    public? || owned_by?(check_user)
  end
end
