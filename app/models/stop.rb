class Stop < ApplicationRecord
  belongs_to :route
  
  validates :name, presence: true
  validates :order, presence: true, uniqueness: { scope: :route_id }
  validates :latitude, presence: true, inclusion: { in: -90.0..90.0 }
  validates :longitude, presence: true, inclusion: { in: -180.0..180.0 }
  
  scope :ordered, -> { order(:order) }
  
  before_validation :set_order, on: :create
  
  private
  
  def set_order
    return if order.present?
    
    last_stop = route&.stops&.maximum(:order)
    self.order = last_stop ? last_stop + 1 : 1
  end
end