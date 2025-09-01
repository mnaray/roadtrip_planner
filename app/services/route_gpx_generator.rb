require "net/http"
require "json"
require "nokogiri"

class RouteGpxGenerator
  def initialize(route)
    @route = route
    @starting_location = route.starting_location
    @destination = route.destination
  end

  def generate
    # Geocode locations
    start_coords = geocode(@starting_location)
    end_coords = geocode(@destination)

    return fallback_gpx unless start_coords && end_coords

    # Try to get actual route data (same logic as JavaScript controller)
    route_data = fetch_route_data(start_coords, end_coords)

    # Check for coordinates with both string and symbol keys for compatibility
    has_coordinates = route_data && route_data[:geometry] && 
                     (route_data[:geometry]["coordinates"] || route_data[:geometry][:coordinates])
    
    if has_coordinates
      generate_gpx_with_route(route_data)
    else
      generate_gpx_with_waypoints(start_coords, end_coords)
    end
  end

  private

  def generate_gpx_with_route(route_data)
    coordinates = route_data[:geometry]["coordinates"] || route_data[:geometry][:coordinates]
    distance = route_data[:distance]
    duration = route_data[:duration]
    
    Rails.logger.info "RouteGpxGenerator: Building GPX with #{coordinates.length} track points" if defined?(Rails) && coordinates

    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.gpx(
        version: "1.1",
        creator: "Road Trip Planner",
        "xmlns" => "http://www.topografix.com/GPX/1/1",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
      ) do
        # Add metadata
        xml.metadata do
          xml.name "Route: #{@starting_location} to #{@destination}"
          xml.desc "Generated from Road Trip Planner - #{@route.datetime.strftime('%B %d, %Y at %l:%M %p')}"
          xml.time @route.datetime.iso8601
          xml.keywords "road trip, route, driving"
        end

        if coordinates && coordinates.any?
          # Add waypoints for start and end (using correct lon,lat order from GeoJSON)
          xml.wpt(lat: coordinates.first[1], lon: coordinates.first[0]) do
            xml.name "Start: #{@starting_location}"
            xml.desc "Starting point of the route"
          end

          xml.wpt(lat: coordinates.last[1], lon: coordinates.last[0]) do
            xml.name "Destination: #{@destination}"
            xml.desc "End point of the route"
          end

          # Add the track with all points
          xml.trk do
            xml.name "Route: #{@starting_location} → #{@destination}"
            xml.desc build_track_description(distance, duration)

            xml.trkseg do
              coordinates.each do |coord|
                # GeoJSON format is [longitude, latitude]
                lon, lat = coord[0], coord[1]
                xml.trkpt(lat: lat.round(6), lon: lon.round(6))
              end
            end
          end
        end
      end
    end

    builder.to_xml
  end

  def generate_gpx_with_waypoints(start_coords, end_coords)
    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.gpx(
        version: "1.1",
        creator: "Road Trip Planner",
        "xmlns" => "http://www.topografix.com/GPX/1/1",
        "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
        "xsi:schemaLocation" => "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd"
      ) do
        # Add metadata
        xml.metadata do
          xml.name "Route: #{@starting_location} to #{@destination}"
          xml.desc "Generated from Road Trip Planner - #{@route.datetime.strftime('%B %d, %Y at %l:%M %p')}"
          xml.time @route.datetime.iso8601
          xml.keywords "road trip, route, driving"
        end

        # Add waypoints
        xml.wpt(lat: start_coords[0], lon: start_coords[1]) do
          xml.name "Start: #{@starting_location}"
          xml.desc "Starting point of the route"
        end

        xml.wpt(lat: end_coords[0], lon: end_coords[1]) do
          xml.name "Destination: #{@destination}"
          xml.desc "End point of the route"
        end

        # Add a simple route (straight line between points)
        xml.rte do
          xml.name "Direct route: #{@starting_location} → #{@destination}"
          xml.desc "Direct waypoint route (detailed routing unavailable)"

          xml.rtept(lat: start_coords[0], lon: start_coords[1]) do
            xml.name @starting_location
          end

          xml.rtept(lat: end_coords[0], lon: end_coords[1]) do
            xml.name @destination
          end
        end
      end
    end

    builder.to_xml
  end

  def build_track_description(distance, duration)
    desc_parts = [ "Road trip route" ]

    if distance
      distance_km = (distance / 1000.0).round(1)
      desc_parts << "Distance: #{distance_km} km"
    end

    if duration
      duration_hours = (duration / 3600.0).round(1)
      desc_parts << "Estimated duration: #{duration_hours} hours"
    end

    desc_parts << "Scheduled: #{@route.datetime.strftime('%B %d, %Y at %l:%M %p')}"

    desc_parts.join(" | ")
  end

  def fetch_route_data(start_coords, end_coords)
    # Try OSRM first (same as JavaScript fallback)
    osrm_data = fetch_osrm_route(start_coords, end_coords)
    return osrm_data if osrm_data

    # Could add more routing services here as fallbacks
    nil
  rescue => e
    Rails.logger.error "Route data fetch failed: #{e.message}"
    nil
  end

  def fetch_osrm_route(start_coords, end_coords)
    # Coordinates from geocoding are [lat, lon]
    start_lat, start_lon = start_coords
    end_lat, end_lon = end_coords

    # OSRM expects lon,lat order in URL
    url = "https://router.project-osrm.org/route/v1/driving/#{start_lon},#{start_lat};#{end_lon},#{end_lat}?overview=full&geometries=geojson"
    
    Rails.logger.info "RouteGpxGenerator: Fetching route from OSRM: #{url}" if defined?(Rails)
    response = Net::HTTP.get_response(URI(url))
    return nil unless response.code == "200"

    data = JSON.parse(response.body)

    if data["routes"] && data["routes"].any?
      route = data["routes"][0]
      geometry = route["geometry"]
      
      if geometry && geometry["coordinates"]
        Rails.logger.info "RouteGpxGenerator: Retrieved #{geometry["coordinates"].length} points from OSRM" if defined?(Rails)
        {
          geometry: geometry,
          distance: route["distance"],
          duration: route["duration"]
        }
      else
        nil
      end
    else
      nil
    end
  rescue => e
    Rails.logger.error "OSRM routing failed: #{e.message}" if defined?(Rails)
    nil
  end

  def geocode(location)
    url = "https://nominatim.openstreetmap.org/search?format=json&q=#{URI.encode_www_form_component(location)}&limit=1"

    response = Net::HTTP.get_response(URI(url))
    return nil unless response.code == "200"

    data = JSON.parse(response.body)

    if data.any?
      [ data[0]["lat"].to_f, data[0]["lon"].to_f ]
    else
      nil
    end
  rescue => e
    Rails.logger.error "Geocoding failed for '#{location}': #{e.message}"
    nil
  end

  def fallback_gpx
    # Return a minimal GPX file if everything fails
    builder = Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.gpx(
        version: "1.1",
        creator: "Road Trip Planner",
        "xmlns" => "http://www.topografix.com/GPX/1/1"
      ) do
        xml.metadata do
          xml.name "Route: #{@starting_location} to #{@destination}"
          xml.desc "Route data temporarily unavailable - please try again later"
          xml.time @route.datetime.iso8601
        end
      end
    end

    builder.to_xml
  end
end
