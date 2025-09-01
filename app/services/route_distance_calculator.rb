require "net/http"
require "json"
require "uri"

class RouteDistanceCalculator
  attr_reader :distance_km, :duration_hours

  def initialize(starting_location, destination)
    @starting_location = starting_location
    @destination = destination
    @distance_km = nil
    @duration_hours = nil
  end

  def calculate
    start_coords = geocode(@starting_location)
    end_coords = geocode(@destination)

    return { distance: nil, duration: nil } unless start_coords && end_coords

    # Try primary routing service
    route_data = fetch_route_data_osrm(start_coords, end_coords)

    # Fallback to straight-line calculations if routing fails
    route_data ||= calculate_straight_line_estimates(start_coords, end_coords)

    if route_data
      # Convert from meters to kilometers and seconds to hours
      @distance_km = route_data[:distance] ? (route_data[:distance] / 1000.0).round(1) : nil
      @duration_hours = route_data[:duration] ? (route_data[:duration] / 3600.0).round(2) : nil
    end

    { distance: @distance_km, duration: @duration_hours }
  end

  # Legacy method for backward compatibility
  def calculate_distance_only
    result = calculate
    result[:distance]
  end

  private

  def geocode(location)
    uri = URI("https://nominatim.openstreetmap.org/search")
    params = {
      format: "json",
      q: location,
      limit: 1
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    return nil if data.empty?

    [ data[0]["lat"].to_f, data[0]["lon"].to_f ]
  rescue StandardError => e
    Rails.logger.error "Geocoding error for '#{location}': #{e.message}"
    nil
  end

  def fetch_route_data_osrm(start_coords, end_coords)
    start_lat, start_lon = start_coords
    end_lat, end_lon = end_coords

    # Using OSRM (Open Source Routing Machine) API
    uri = URI("https://router.project-osrm.org/route/v1/driving/#{start_lon},#{start_lat};#{end_lon},#{end_lat}")
    params = {
      overview: "false",
      geometries: "geojson"
    }
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return nil unless response.is_a?(Net::HTTPSuccess)

    data = JSON.parse(response.body)
    return nil unless data["routes"] && data["routes"].any?

    route = data["routes"][0]
    # Distance is in meters, duration is in seconds
    { distance: route["distance"], duration: route["duration"] }
  rescue StandardError => e
    Rails.logger.error "OSRM routing error: #{e.message}"
    nil
  end

  def calculate_straight_line_estimates(start_coords, end_coords)
    distance_meters = calculate_straight_line_distance(start_coords, end_coords)

    # Estimate duration based on average driving speed
    # Assuming 60 km/h average speed for estimation
    average_speed_mps = 60 / 3.6  # Convert km/h to m/s
    estimated_duration_seconds = distance_meters / average_speed_mps

    { distance: distance_meters, duration: estimated_duration_seconds }
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
