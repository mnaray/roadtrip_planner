require "net/http"
require "json"
require "uri"

class RouteDistanceCalculator
  attr_reader :distance_km, :duration_hours

  def initialize(starting_location, destination, waypoints = [])
    @starting_location = starting_location
    @destination = destination
    @waypoints = waypoints || []
    @distance_km = nil
    @duration_hours = nil
  end

  def calculate
    start_coords = geocode(@starting_location)
    end_coords = geocode(@destination)

    return { distance: nil, duration: nil } unless start_coords && end_coords

    # If waypoints are present, calculate route with waypoints
    route_data = if @waypoints.any?
                   calculate_with_waypoints(start_coords, end_coords)
                 else
                   # Original behavior for routes without waypoints
                   fetch_route_data_osrm(start_coords, end_coords)
                 end

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

  # Calculate route with waypoints using coordinates
  def calculate_with_waypoints_from_coordinates(start_coords, waypoint_coords, end_coords)
    return { distance: nil, duration: nil } unless start_coords && end_coords

    # Build coordinates array: start -> waypoints (ordered) -> end
    all_coords = [start_coords] + waypoint_coords + [end_coords]

    # Fetch route data with all waypoints
    route_data = fetch_route_data_osrm_with_waypoints(all_coords)

    # Fallback to multiple segments if single request fails
    route_data ||= calculate_multi_segment_route(all_coords)

    route_data
  end

  private

  def calculate_with_waypoints(start_coords, end_coords)
    # Geocode waypoints
    waypoint_coords = @waypoints.map do |waypoint|
      if waypoint.respond_to?(:latitude) && waypoint.respond_to?(:longitude)
        # Waypoint is an AR model with lat/lon
        [waypoint.latitude, waypoint.longitude]
      elsif waypoint.is_a?(Hash) && waypoint[:latitude] && waypoint[:longitude]
        # Waypoint is a hash with lat/lon keys
        [waypoint[:latitude], waypoint[:longitude]]
      elsif waypoint.is_a?(Array) && waypoint.length >= 2
        # Waypoint is already coordinates array
        waypoint
      else
        # Try to geocode if it's a string location name
        geocode(waypoint.to_s)
      end
    end.compact

    return { distance: nil, duration: nil } if waypoint_coords.empty?

    calculate_with_waypoints_from_coordinates(start_coords, waypoint_coords, end_coords)
  end

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

  def fetch_route_data_osrm_with_waypoints(coords_array)
    return nil if coords_array.length < 2

    # Format coordinates for OSRM: lon,lat;lon,lat;...
    coords_string = coords_array.map do |coord|
      lat, lon = coord
      "#{lon},#{lat}"
    end.join(";")

    # Using OSRM (Open Source Routing Machine) API with waypoints
    uri = URI("https://router.project-osrm.org/route/v1/driving/#{coords_string}")
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
    Rails.logger.error "OSRM waypoint routing error: #{e.message}"
    nil
  end

  def calculate_multi_segment_route(coords_array)
    return nil if coords_array.length < 2

    total_distance = 0
    total_duration = 0

    # Calculate route for each segment: coord[i] -> coord[i+1]
    (coords_array.length - 1).times do |i|
      segment_data = fetch_route_data_osrm(coords_array[i], coords_array[i + 1])

      if segment_data
        total_distance += segment_data[:distance] || 0
        total_duration += segment_data[:duration] || 0
      else
        # If any segment fails, fall back to straight-line for that segment
        segment_distance = calculate_straight_line_distance(coords_array[i], coords_array[i + 1])
        total_distance += segment_distance
        total_duration += segment_distance / (60 / 3.6)  # Assume 60 km/h for fallback
      end
    end

    { distance: total_distance, duration: total_duration }
  rescue StandardError => e
    Rails.logger.error "Multi-segment routing error: #{e.message}"
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
