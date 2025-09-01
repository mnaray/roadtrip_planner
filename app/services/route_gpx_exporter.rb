require "nokogiri"
require "net/http"
require "json"
require "uri"

# Service class for exporting Route objects to standards-compliant GPX 1.1 XML format
# GPX (GPS Exchange Format) is an XML schema for GPS data interchange
class RouteGpxExporter
  # GPX 1.1 standard namespaces
  GPX_NAMESPACES = {
    "xmlns" => "http://www.topografix.com/GPX/1/1",
    "xmlns:xsi" => "http://www.w3.org/2001/XMLSchema-instance",
    "xsi:schemaLocation" => "http://www.topografix.com/GPX/1/1 http://www.topografix.com/GPX/1/1/gpx.xsd",
    "xmlns:gpxtpx" => "http://www.garmin.com/xmlschemas/TrackPointExtension/v1"
  }.freeze

  GPX_VERSION = "1.1".freeze
  CREATOR = "RoadTrip Planner v1.0".freeze

  def initialize(route)
    @route = route
    @track_points = []
  end

  # Main method to generate GPX XML
  # @return [String] GPX XML document as string
  def generate
    fetch_route_geometry
    build_gpx_document.to_xml
  end

  # Generate and validate GPX output
  # @return [Hash] Result with :success, :gpx, and optional :errors keys
  def generate_with_validation
    gpx_content = generate
    validation_result = validate_gpx(gpx_content)

    {
      success: validation_result[:valid],
      gpx: gpx_content,
      errors: validation_result[:errors]
    }
  end

  private

  # Build the GPX XML document structure
  def build_gpx_document
    Nokogiri::XML::Builder.new(encoding: "UTF-8") do |xml|
      xml.gpx(gpx_attributes) do
        add_metadata(xml)
        add_waypoints(xml)
        add_track(xml)
      end
    end
  end

  # GPX root element attributes
  def gpx_attributes
    GPX_NAMESPACES.merge(
      "version" => GPX_VERSION,
      "creator" => CREATOR
    )
  end

  # Add metadata element (required for GPX 1.1)
  def add_metadata(xml)
    xml.metadata do
      xml.name route_name
      xml.desc route_description
      xml.author do
        xml.name "RoadTrip Planner"
        xml.email(id: "support", domain: "roadtripplanner.com")
      end
      xml.copyright(author: "RoadTrip Planner") do
        xml.year Time.current.year
        xml.license "https://creativecommons.org/licenses/by-sa/4.0/"
      end
      xml.link(href: "https://roadtripplanner.com") do
        xml.text "RoadTrip Planner"
        xml.type "text/html"
      end
      xml.time @route.datetime.utc.iso8601
      xml.keywords "road trip, driving route, navigation, #{@route.starting_location}, #{@route.destination}"

      # Add bounds if track points are available
      add_bounds(xml) if @track_points.any?
    end
  end

  # Add bounds element based on track points
  def add_bounds(xml)
    lats = @track_points.map { |pt| pt[:lat] }
    lons = @track_points.map { |pt| pt[:lon] }

    xml.bounds(
      minlat: lats.min,
      minlon: lons.min,
      maxlat: lats.max,
      maxlon: lons.max
    )
  end

  # Add waypoints for start and destination
  def add_waypoints(xml)
    # Starting waypoint
    if @track_points.any?
      start_point = @track_points.first
      xml.wpt(lat: start_point[:lat], lon: start_point[:lon]) do
        xml.ele start_point[:ele] if start_point[:ele]
        xml.time @route.datetime.utc.iso8601
        xml.name "Start: #{@route.starting_location}"
        xml.desc "Starting point of the route"
        xml.sym "Flag, Green"
        xml.type "Route Start"
        add_waypoint_extensions(xml, start_point)
      end
    end

    # Destination waypoint
    if @track_points.any?
      end_point = @track_points.last
      xml.wpt(lat: end_point[:lat], lon: end_point[:lon]) do
        xml.ele end_point[:ele] if end_point[:ele]

        # Calculate arrival time based on duration
        arrival_time = @route.datetime + @route.duration_hours.hours
        xml.time arrival_time.utc.iso8601

        xml.name "End: #{@route.destination}"
        xml.desc "Destination point of the route"
        xml.sym "Flag, Red"
        xml.type "Route End"
        add_waypoint_extensions(xml, end_point)
      end
    end
  end

  # Add track element with segments
  def add_track(xml)
    xml.trk do
      xml.name route_name
      xml.desc route_description
      xml.src "RoadTrip Planner Route Service"
      xml.type "Driving"

      # Add link to the route
      if defined?(Rails) && Rails.application
        xml.link(href: route_url) do
          xml.text "View route on RoadTrip Planner"
          xml.type "text/html"
        end
      end

      # Add track segment with points
      add_track_segment(xml)

      # Add track extensions for additional data
      add_track_extensions(xml)
    end
  end

  # Add track segment containing all track points
  def add_track_segment(xml)
    return unless @track_points.any?

    xml.trkseg do
      @track_points.each_with_index do |point, index|
        xml.trkpt(lat: point[:lat], lon: point[:lon]) do
          # Elevation (optional but recommended)
          xml.ele point[:ele] if point[:ele]

          # Time for each point (interpolated based on route progress)
          point_time = calculate_point_time(index)
          xml.time point_time.utc.iso8601

          # Optional elements for enhanced GPS data
          xml.magvar point[:magvar] if point[:magvar]
          xml.geoidheight point[:geoidheight] if point[:geoidheight]
          xml.name point[:name] if point[:name]
          xml.cmt point[:comment] if point[:comment]
          xml.desc point[:description] if point[:description]
          xml.src point[:source] || "OSRM"
          xml.sym point[:symbol] if point[:symbol]
          xml.type point[:type] if point[:type]
          xml.fix point[:fix] || "2d"
          xml.sat point[:satellites] if point[:satellites]
          xml.hdop point[:hdop] if point[:hdop]
          xml.vdop point[:vdop] if point[:vdop]
          xml.pdop point[:pdop] if point[:pdop]
          xml.ageofdgpsdata point[:ageofdgpsdata] if point[:ageofdgpsdata]
          xml.dgpsid point[:dgpsid] if point[:dgpsid]

          # Add extensions for track point
          add_track_point_extensions(xml, point)
        end
      end
    end
  end

  # Add Garmin extensions for track
  def add_track_extensions(xml)
    xml.extensions do
      xml.send("gpxx:TrackExtension", "xmlns:gpxx" => "http://www.garmin.com/xmlschemas/GpxExtensions/v3") do
        xml.send("gpxx:DisplayColor", "Blue")
        xml.send("gpxx:RouteType", "Driving")
      end
    end
  end

  # Add Garmin extensions for track points
  def add_track_point_extensions(xml, point)
    return unless point[:speed] || point[:course] || point[:temperature]

    xml.extensions do
      xml.send("gpxtpx:TrackPointExtension") do
        xml.send("gpxtpx:speed", point[:speed]) if point[:speed]
        xml.send("gpxtpx:course", point[:course]) if point[:course]
        xml.send("gpxtpx:temp", point[:temperature]) if point[:temperature]
      end
    end
  end

  # Add extensions for waypoints
  def add_waypoint_extensions(xml, point)
    return unless point[:address] || point[:phone]

    xml.extensions do
      xml.send("gpxx:WaypointExtension", "xmlns:gpxx" => "http://www.garmin.com/xmlschemas/GpxExtensions/v3") do
        xml.send("gpxx:Address") do
          xml.send("gpxx:StreetAddress", point[:address]) if point[:address]
          xml.send("gpxx:City", point[:city]) if point[:city]
          xml.send("gpxx:State", point[:state]) if point[:state]
          xml.send("gpxx:Country", point[:country]) if point[:country]
          xml.send("gpxx:PostalCode", point[:postal_code]) if point[:postal_code]
        end
        xml.send("gpxx:PhoneNumber", point[:phone]) if point[:phone]
      end
    end
  end

  # Fetch route geometry and elevation data
  def fetch_route_geometry
    # Get route coordinates from OSRM
    coordinates = fetch_osrm_route

    # Convert to track points with optional elevation
    if coordinates && coordinates.any?
      @track_points = coordinates.map do |coord|
        # OSRM returns [longitude, latitude] in GeoJSON format
        lon, lat = coord[0], coord[1]
        elevation = coord[2] if coord.length > 2 # OSRM may include elevation as third coordinate

        point = {
          lat: lat.round(6),
          lon: lon.round(6)
        }

        # Add elevation if available or fetch it
        point[:ele] = elevation || fetch_elevation(lat, lon)

        point
      end
      
      Rails.logger.info "RouteGpxExporter: Converted #{@track_points.length} track points from OSRM" if defined?(Rails)
    else
      # Fallback to simple start/end points
      Rails.logger.warn "RouteGpxExporter: No OSRM data, falling back to endpoints" if defined?(Rails)
      fetch_endpoint_coordinates
    end
  end

  # Fetch route from OSRM API
  def fetch_osrm_route
    start_coords = geocode(@route.starting_location)
    end_coords = geocode(@route.destination)

    return nil unless start_coords && end_coords

    url = build_osrm_url(start_coords, end_coords)
    Rails.logger.info "RouteGpxExporter: Fetching route from OSRM: #{url}" if defined?(Rails)
    
    response = Net::HTTP.get_response(URI(url))

    return nil unless response.code == "200"

    data = JSON.parse(response.body)

    if data["routes"] && data["routes"].any?
      route = data["routes"].first
      geometry = route["geometry"]

      if geometry && geometry["coordinates"]
        coordinates = geometry["coordinates"]
        Rails.logger.info "RouteGpxExporter: Retrieved #{coordinates.length} points from OSRM" if defined?(Rails)
        coordinates
      else
        Rails.logger.warn "RouteGpxExporter: No geometry in OSRM response" if defined?(Rails)
        nil
      end
    else
      Rails.logger.warn "RouteGpxExporter: No routes in OSRM response" if defined?(Rails)
      nil
    end
  rescue StandardError => e
    Rails.logger.error "OSRM route fetch failed: #{e.message}" if defined?(Rails)
    nil
  end

  # Build OSRM API URL
  def build_osrm_url(start_coords, end_coords)
    # Coordinates are [lat, lon] from geocoding
    start_lat, start_lon = start_coords
    end_lat, end_lon = end_coords

    # OSRM expects lon,lat order
    base_url = "https://router.project-osrm.org/route/v1/driving"
    coordinates = "#{start_lon},#{start_lat};#{end_lon},#{end_lat}"
    parameters = "overview=full&geometries=geojson&steps=true&annotations=true"

    "#{base_url}/#{coordinates}?#{parameters}"
  end

  # Geocode a location string to coordinates
  def geocode(location)
    url = "https://nominatim.openstreetmap.org/search"
    params = {
      q: location,
      format: "json",
      limit: 1,
      addressdetails: 1
    }

    uri = URI(url)
    uri.query = URI.encode_www_form(params)

    response = Net::HTTP.get_response(uri)
    return nil unless response.code == "200"

    data = JSON.parse(response.body)

    if data.any?
      result = data.first
      [ result["lat"].to_f, result["lon"].to_f ]
    end
  rescue StandardError => e
    Rails.logger.error "Geocoding failed for '#{location}': #{e.message}" if defined?(Rails)
    nil
  end

  # Fetch elevation for a coordinate (optional enhancement)
  def fetch_elevation(lat, lon)
    # This would typically call an elevation API service
    # For now, return nil or a default value
    # Example services: Open-Elevation, Mapbox Elevation API
    nil
  end

  # Fallback to fetch just endpoint coordinates
  def fetch_endpoint_coordinates
    start_coords = geocode(@route.starting_location)
    end_coords = geocode(@route.destination)

    return unless start_coords && end_coords

    @track_points = [
      { lat: start_coords[0], lon: start_coords[1] },
      { lat: end_coords[0], lon: end_coords[1] }
    ]
  end

  # Calculate interpolated time for a track point
  def calculate_point_time(index)
    return @route.datetime if index == 0
    return @route.datetime + @route.duration_hours.hours if index == @track_points.length - 1

    # Interpolate time based on position in route
    progress = index.to_f / (@track_points.length - 1)
    @route.datetime + (progress * @route.duration_hours).hours
  end

  # Generate route name
  def route_name
    "Route: #{@route.starting_location} to #{@route.destination}"
  end

  # Generate route description
  def route_description
    parts = []
    parts << "Road trip route from #{@route.starting_location} to #{@route.destination}"
    parts << "Distance: #{@route.distance_in_km} km" if @route.distance_in_km
    parts << "Duration: #{format_duration(@route.duration_hours)}" if @route.duration_hours
    parts << "Scheduled: #{@route.datetime.strftime('%B %d, %Y at %l:%M %p')}"
    parts << "Trip: #{@route.road_trip.name}" if @route.road_trip

    parts.join(" | ")
  end

  # Format duration for display
  def format_duration(hours)
    return nil unless hours

    if hours < 1
      "#{(hours * 60).round} minutes"
    elsif hours == hours.to_i
      "#{hours.to_i} hours"
    else
      hours_part = hours.to_i
      minutes_part = ((hours - hours_part) * 60).round
      "#{hours_part} hours #{minutes_part} minutes"
    end
  end

  # Generate URL for the route (if in Rails context)
  def route_url
    return "" unless defined?(Rails) && Rails.application

    Rails.application.routes.url_helpers.route_url(@route, host: "roadtripplanner.com")
  rescue StandardError
    ""
  end

  # Validate GPX output against schema
  def validate_gpx(gpx_content)
    # Basic validation - check for required elements
    doc = Nokogiri::XML(gpx_content)
    errors = []

    # Check root element
    errors << "Missing GPX root element" unless doc.root&.name == "gpx"

    # Check version
    errors << "Missing or invalid GPX version" unless doc.root&.attr("version") == "1.1"

    # Check required namespaces
    errors << "Missing GPX namespace" unless doc.root&.namespace&.href == "http://www.topografix.com/GPX/1/1"

    # Check for at least one of: wpt, rte, or trk
    has_content = doc.xpath("//gpx:wpt | //gpx:rte | //gpx:trk", "gpx" => "http://www.topografix.com/GPX/1/1").any?
    errors << "GPX must contain at least one waypoint, route, or track" unless has_content

    {
      valid: errors.empty?,
      errors: errors
    }
  rescue StandardError => e
    {
      valid: false,
      errors: [ "XML parsing error: #{e.message}" ]
    }
  end
end
