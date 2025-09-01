# frozen_string_literal: true

require "nokogiri"

# RSpec helper methods for validating GPX XML output
module GpxHelpers
  # Main validation method that parses and validates GPX content
  # @param gpx_content [String] The GPX XML content to validate
  # @param options [Hash] Validation options
  # @option options [Integer] :min_track_points Minimum expected track points (default: 2)
  # @option options [Boolean] :require_waypoints Whether waypoints are required (default: true)
  # @option options [Boolean] :require_metadata Whether metadata is required (default: true)
  # @return [Nokogiri::XML::Document] The parsed GPX document for further assertions
  def validate_gpx_structure(gpx_content, options = {})
    # Parse the GPX content
    doc = parse_gpx(gpx_content)

    # Validate root element and attributes
    validate_gpx_root(doc)

    # Validate required sections based on options
    validate_gpx_metadata(doc) if options.fetch(:require_metadata, true)
    validate_gpx_waypoints(doc) if options.fetch(:require_waypoints, true)

    # Validate track points
    min_points = options.fetch(:min_track_points, 2)
    validate_gpx_track_points(doc, min_points)

    doc
  end

  # Parse GPX content and ensure it's valid XML
  def parse_gpx(gpx_content)
    expect(gpx_content).not_to be_nil, "GPX content should not be nil"
    expect(gpx_content).to be_a(String), "GPX content should be a string"

    doc = Nokogiri::XML(gpx_content) do |config|
      config.strict # Enforce strict XML parsing
    end

    expect(doc.errors).to be_empty, "GPX should be valid XML: #{doc.errors.join(', ')}"
    doc
  end

  # Validate the GPX root element and its required attributes
  def validate_gpx_root(doc)
    root = doc.root

    # Check root element name
    expect(root).not_to be_nil, "GPX document should have a root element"
    expect(root.name).to eq("gpx"), "Root element should be <gpx>"

    # Check required GPX version
    version = root["version"]
    expect(version).not_to be_nil, "GPX root should have a version attribute"
    expect(version).to eq("1.1"), "GPX version should be 1.1 (got: #{version})"

    # Check required namespace
    namespace = root.namespace
    expect(namespace).not_to be_nil, "GPX root should have a namespace"
    expect(namespace.href).to eq("http://www.topografix.com/GPX/1/1"),
                            "GPX namespace should be correct (got: #{namespace.href})"

    # Check creator attribute
    creator = root["creator"]
    expect(creator).not_to be_nil, "GPX root should have a creator attribute"

    # Check schema location for proper validation
    schema_location = root["xsi:schemaLocation"] || root.attribute_with_ns("schemaLocation", "http://www.w3.org/2001/XMLSchema-instance")
    expect(schema_location).not_to be_nil, "GPX should include schema location for validation"
    expect(schema_location.to_s).to include("http://www.topografix.com/GPX/1/1"),
                                    "Schema location should reference GPX 1.1 schema"
  end

  # Validate GPX metadata section
  def validate_gpx_metadata(doc)
    metadata = doc.at_xpath("//gpx:metadata", gpx: "http://www.topografix.com/GPX/1/1")
    expect(metadata).not_to be_nil, "GPX should contain metadata element"

    # Check required metadata elements
    name = metadata.at_xpath("gpx:name", gpx: "http://www.topografix.com/GPX/1/1")
    expect(name).not_to be_nil, "Metadata should contain name element"
    expect(name.text).not_to be_empty, "Metadata name should not be empty"

    # Check optional but recommended metadata
    desc = metadata.at_xpath("gpx:desc", gpx: "http://www.topografix.com/GPX/1/1")
    time = metadata.at_xpath("gpx:time", gpx: "http://www.topografix.com/GPX/1/1")

    # If time is present, validate format
    if time
      expect { Time.parse(time.text) }.not_to raise_error,
                                         "Metadata time should be valid ISO 8601 format"
    end
  end

  # Validate waypoints in GPX
  def validate_gpx_waypoints(doc)
    waypoints = doc.xpath("//gpx:wpt", gpx: "http://www.topografix.com/GPX/1/1")

    waypoints.each_with_index do |wpt, index|
      # Validate required attributes
      lat = wpt["lat"]
      lon = wpt["lon"]

      expect(lat).not_to be_nil, "Waypoint #{index + 1} should have lat attribute"
      expect(lon).not_to be_nil, "Waypoint #{index + 1} should have lon attribute"

      # Validate coordinate ranges
      validate_coordinate(lat.to_f, lon.to_f, "Waypoint #{index + 1}")

      # Check for name (recommended)
      name = wpt.at_xpath("gpx:name", gpx: "http://www.topografix.com/GPX/1/1")
      expect(name).not_to be_nil, "Waypoint #{index + 1} should have a name"
    end
  end

  # Validate track points in GPX
  def validate_gpx_track_points(doc, min_points = 2)
    tracks = doc.xpath("//gpx:trk", gpx: "http://www.topografix.com/GPX/1/1")

    if tracks.any?
      tracks.each_with_index do |track, track_index|
        # Check track has name
        track_name = track.at_xpath("gpx:name", gpx: "http://www.topografix.com/GPX/1/1")
        expect(track_name).not_to be_nil, "Track #{track_index + 1} should have a name"

        # Check track segments
        segments = track.xpath("gpx:trkseg", gpx: "http://www.topografix.com/GPX/1/1")
        expect(segments).not_to be_empty, "Track #{track_index + 1} should have at least one segment"

        # Validate track points
        all_track_points = []
        segments.each_with_index do |segment, seg_index|
          track_points = segment.xpath("gpx:trkpt", gpx: "http://www.topografix.com/GPX/1/1")
          all_track_points.concat(track_points)

          track_points.each_with_index do |trkpt, pt_index|
            validate_track_point(trkpt, "Track #{track_index + 1}, Segment #{seg_index + 1}, Point #{pt_index + 1}")
          end
        end

        # Validate minimum points requirement
        expect(all_track_points.length).to be >= min_points,
          "Track should have at least #{min_points} points (got: #{all_track_points.length})"
      end
    else
      # If no tracks, check for routes as alternative
      routes = doc.xpath("//gpx:rte", gpx: "http://www.topografix.com/GPX/1/1")
      expect(tracks.any? || routes.any?).to be(true),
        "GPX should contain at least one track or route"
    end
  end

  # Validate individual track point
  def validate_track_point(trkpt, context = "Track point")
    lat = trkpt["lat"]
    lon = trkpt["lon"]

    expect(lat).not_to be_nil, "#{context} should have lat attribute"
    expect(lon).not_to be_nil, "#{context} should have lon attribute"

    validate_coordinate(lat.to_f, lon.to_f, context)

    # Check optional elements
    ele = trkpt.at_xpath("gpx:ele", gpx: "http://www.topografix.com/GPX/1/1")
    time = trkpt.at_xpath("gpx:time", gpx: "http://www.topografix.com/GPX/1/1")

    # Validate elevation if present
    if ele
      elevation = ele.text.to_f
      expect(elevation).to be_between(-500, 9000),
        "#{context} elevation should be realistic (got: #{elevation}m)"
    end

    # Validate time if present
    if time
      expect { Time.parse(time.text) }.not_to raise_error,
        "#{context} time should be valid ISO 8601 format"
    end
  end

  # Validate coordinate values are within valid ranges
  def validate_coordinate(lat, lon, context = "Coordinate")
    expect(lat).to be_between(-90, 90),
      "#{context} latitude should be between -90 and 90 (got: #{lat})"
    expect(lon).to be_between(-180, 180),
      "#{context} longitude should be between -180 and 180 (got: #{lon})"
  end

  # Helper to extract all track points from a GPX document
  def extract_track_points(doc)
    doc.xpath("//gpx:trkpt", gpx: "http://www.topografix.com/GPX/1/1").map do |trkpt|
      {
        lat: trkpt["lat"].to_f,
        lon: trkpt["lon"].to_f,
        ele: trkpt.at_xpath("gpx:ele", gpx: "http://www.topografix.com/GPX/1/1")&.text&.to_f,
        time: trkpt.at_xpath("gpx:time", gpx: "http://www.topografix.com/GPX/1/1")&.text
      }
    end
  end

  # Helper to extract waypoints from a GPX document
  def extract_waypoints(doc)
    doc.xpath("//gpx:wpt", gpx: "http://www.topografix.com/GPX/1/1").map do |wpt|
      {
        lat: wpt["lat"].to_f,
        lon: wpt["lon"].to_f,
        name: wpt.at_xpath("gpx:name", gpx: "http://www.topografix.com/GPX/1/1")&.text,
        desc: wpt.at_xpath("gpx:desc", gpx: "http://www.topografix.com/GPX/1/1")&.text
      }
    end
  end

  # Validate that GPX contains actual route geometry (not just endpoints)
  def validate_detailed_route(doc, min_points: 100)
    track_points = extract_track_points(doc)

    expect(track_points.length).to be >= min_points,
      "GPX should contain detailed route with at least #{min_points} points (got: #{track_points.length})"

    # Validate that points form a continuous path (no huge jumps)
    if track_points.length > 1
      track_points.each_cons(2).with_index do |(pt1, pt2), index|
        distance = calculate_distance(pt1[:lat], pt1[:lon], pt2[:lat], pt2[:lon])

        # Alert if distance between consecutive points is unreasonably large (> 10km)
        expect(distance).to be < 10.0,
          "Distance between points #{index} and #{index + 1} is too large (#{distance.round(2)}km)"
      end
    end

    track_points
  end

  # Calculate distance between two coordinates (simplified Haversine formula)
  def calculate_distance(lat1, lon1, lat2, lon2)
    rad_per_deg = Math::PI / 180
    earth_radius = 6371 # km

    dlat = (lat2 - lat1) * rad_per_deg
    dlon = (lon2 - lon1) * rad_per_deg

    a = Math.sin(dlat / 2)**2 +
        Math.cos(lat1 * rad_per_deg) * Math.cos(lat2 * rad_per_deg) *
        Math.sin(dlon / 2)**2

    c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a))
    earth_radius * c
  end

  # Validate GPX against specific route expectations
  def validate_route_gpx(gpx_content, route)
    doc = validate_gpx_structure(gpx_content)

    # Check metadata contains route information
    metadata = doc.at_xpath("//gpx:metadata", gpx: "http://www.topografix.com/GPX/1/1")
    name = metadata.at_xpath("gpx:name", gpx: "http://www.topografix.com/GPX/1/1")

    expect(name.text).to include(route.starting_location),
      "GPX name should include starting location"
    expect(name.text).to include(route.destination),
      "GPX name should include destination"

    # Validate waypoints match route
    waypoints = extract_waypoints(doc)
    expect(waypoints).not_to be_empty, "GPX should have waypoints for start and end"

    # Validate track points form complete route
    track_points = validate_detailed_route(doc, min_points: 10)

    # First and last points should be near route start/end
    # (This would need actual geocoding to validate precisely)

    doc
  end
end

# Include the module in RSpec configuration
RSpec.configure do |config|
  config.include GpxHelpers
end
