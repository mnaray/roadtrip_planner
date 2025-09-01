require 'net/http'
require 'json'
require 'uri'

class RouteDistanceCalculator
  def initialize(starting_location, destination)
    @starting_location = starting_location
    @destination = destination
  end

  def calculate
    start_coords = geocode(@starting_location)
    end_coords = geocode(@destination)
    
    return nil unless start_coords && end_coords
    
    # Try primary routing service
    distance = fetch_route_distance_osrm(start_coords, end_coords)
    
    # Fallback to straight-line distance if routing fails
    distance ||= calculate_straight_line_distance(start_coords, end_coords)
    
    # Convert from meters to kilometers
    distance ? (distance / 1000.0).round(1) : nil
  end

  private

  def geocode(location)
    uri = URI("https://nominatim.openstreetmap.org/search")
    params = {
      format: 'json',
      q: location,
      limit: 1
    }
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)
    
    data = JSON.parse(response.body)
    return nil if data.empty?
    
    [data[0]['lat'].to_f, data[0]['lon'].to_f]
  rescue StandardError => e
    Rails.logger.error "Geocoding error for '#{location}': #{e.message}"
    nil
  end

  def fetch_route_distance_osrm(start_coords, end_coords)
    start_lat, start_lon = start_coords
    end_lat, end_lon = end_coords
    
    # Using OSRM (Open Source Routing Machine) API
    uri = URI("https://router.project-osrm.org/route/v1/driving/#{start_lon},#{start_lat};#{end_lon},#{end_lat}")
    params = {
      overview: 'false',
      geometries: 'geojson'
    }
    uri.query = URI.encode_www_form(params)
    
    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)
    
    data = JSON.parse(response.body)
    return nil unless data['routes'] && data['routes'].any?
    
    # Distance is returned in meters
    data['routes'][0]['distance']
  rescue StandardError => e
    Rails.logger.error "OSRM routing error: #{e.message}"
    nil
  end

  def calculate_straight_line_distance(start_coords, end_coords)
    # Haversine formula for calculating great-circle distance
    lat1, lon1 = start_coords
    lat2, lon2 = end_coords
    
    # Earth's radius in meters
    radius = 6371000
    
    # Convert to radians
    lat1_rad = lat1 * Math::PI / 180
    lat2_rad = lat2 * Math::PI / 180
    delta_lat = (lat2 - lat1) * Math::PI / 180
    delta_lon = (lon2 - lon1) * Math::PI / 180
    
    a = Math.sin(delta_lat / 2) * Math.sin(delta_lat / 2) +
        Math.cos(lat1_rad) * Math.cos(lat2_rad) *
        Math.sin(delta_lon / 2) * Math.sin(delta_lon / 2)
    
    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    
    # Distance in meters
    radius * c
  end
end