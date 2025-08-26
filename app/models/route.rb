class Route < ApplicationRecord
  belongs_to :trip
  has_many :stops, dependent: :destroy
  
  validates :name, presence: true
  validates :day_number, presence: true, uniqueness: { scope: :trip_id }
  
  scope :ordered, -> { order(:day_number) }
  
  def ordered_stops
    stops.order(:order)
  end
  
  def to_gpx
    # TODO: Implement GPX export when gpx gem is added
    # gpx_file = GPX::GPXFile.new
    # gpx_track = GPX::Track.new
    # gpx_segment = GPX::Segment.new
    
    # ordered_stops.each do |stop|
    #   next unless stop.latitude && stop.longitude
      
    #   point = GPX::TrackPoint.new(
    #     lat: stop.latitude,
    #     lon: stop.longitude,
    #     name: stop.name,
    #     time: stop.arrival_time
    #   )
    #   gpx_segment.points << point
    # end
    
    # gpx_track.segments << gpx_segment
    # gpx_file.tracks << gpx_track
    # gpx_file.to_s
    
    "GPX export not yet implemented"
  end
end