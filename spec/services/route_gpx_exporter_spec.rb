require "rails_helper"
require "support/gpx_helpers"

RSpec.describe RouteGpxExporter, type: :service do
  let(:user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let(:route) do
    create(:route,
           starting_location: "San Francisco, CA",
           destination: "Los Angeles, CA",
           datetime: 2.days.from_now,
           road_trip: road_trip,
           user: user)
  end

  let(:exporter) { described_class.new(route) }

  describe "#generate" do
    context "with valid route" do
      let(:gpx_content) { exporter.generate }

      it "generates valid GPX 1.1 XML" do
        # Use the helper to validate GPX structure
        doc = validate_gpx_structure(gpx_content)
        expect(doc).not_to be_nil
      end

      it "includes correct GPX root attributes" do
        doc = parse_gpx(gpx_content)
        validate_gpx_root(doc)

        # Additional specific checks
        root = doc.root
        expect(root["version"]).to eq("1.1")
        expect(root["creator"]).to eq("RoadTrip Planner v1.0")
      end

      it "includes comprehensive metadata" do
        doc = parse_gpx(gpx_content)
        validate_gpx_metadata(doc)

        metadata = doc.at_xpath("//gpx:metadata", gpx: "http://www.topografix.com/GPX/1/1")

        # Check specific metadata content
        name = metadata.at_xpath("gpx:name", gpx: "http://www.topografix.com/GPX/1/1")
        expect(name.text).to include(route.starting_location)
        expect(name.text).to include(route.destination)

        # Check author information
        author = metadata.at_xpath("gpx:author", gpx: "http://www.topografix.com/GPX/1/1")
        expect(author).not_to be_nil

        # Check time is properly formatted
        time = metadata.at_xpath("gpx:time", gpx: "http://www.topografix.com/GPX/1/1")
        expect(time.text).to match(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/)
      end

      it "includes waypoints for start and destination" do
        doc = parse_gpx(gpx_content)
        waypoints = extract_waypoints(doc)

        expect(waypoints.length).to eq(2)

        # Check start waypoint
        start_wpt = waypoints.first
        expect(start_wpt[:name]).to include("Start")
        expect(start_wpt[:name]).to include(route.starting_location)

        # Check end waypoint
        end_wpt = waypoints.last
        expect(end_wpt[:name]).to include("End")
        expect(end_wpt[:name]).to include(route.destination)
      end

      it "includes track with route name and description" do
        doc = parse_gpx(gpx_content)

        track = doc.at_xpath("//gpx:trk", gpx: "http://www.topografix.com/GPX/1/1")
        expect(track).not_to be_nil

        track_name = track.at_xpath("gpx:name", gpx: "http://www.topografix.com/GPX/1/1")
        expect(track_name.text).to include(route.starting_location)
        expect(track_name.text).to include(route.destination)

        track_desc = track.at_xpath("gpx:desc", gpx: "http://www.topografix.com/GPX/1/1")
        expect(track_desc).not_to be_nil
      end

      context "when OSRM returns detailed route" do
        before do
          # Mock OSRM response with realistic nearby route points
          allow_any_instance_of(RouteGpxExporter).to receive(:fetch_osrm_route).and_return(
            [
              [ -122.4194, 37.7749 ], # San Francisco
              [ -122.4180, 37.7700 ], # Intermediate point (close)
              [ -122.4160, 37.7650 ], # Intermediate point (close)
              [ -122.4140, 37.7600 ]  # End point (close - not LA to avoid distance issues)
            ]
          )
        end

        it "includes all route points as track points" do
          doc = parse_gpx(gpx_content)
          track_points = extract_track_points(doc)

          expect(track_points.length).to eq(4)

          # Verify first point (San Francisco)
          expect(track_points.first[:lat]).to be_within(0.01).of(37.7749)
          expect(track_points.first[:lon]).to be_within(0.01).of(-122.4194)

          # Verify last point
          expect(track_points.last[:lat]).to be_within(0.01).of(37.7600)
          expect(track_points.last[:lon]).to be_within(0.01).of(-122.4140)
        end

        it "validates route continuity" do
          doc = parse_gpx(gpx_content)

          # This will check that consecutive points aren't too far apart
          track_points = validate_detailed_route(doc, min_points: 4)
          expect(track_points).not_to be_empty
        end
      end

      context "when route has many track points" do
        before do
          # Mock a realistic route with many points
          points = Array.new(100) do |i|
            # Generate points along a path
            lat = 37.7749 - (i * 0.037)  # Gradually move south
            lon = -122.4194 + (i * 0.042) # Gradually move east
            [ lon, lat ]
          end

          allow_any_instance_of(RouteGpxExporter).to receive(:fetch_osrm_route).and_return(points)
        end

        it "includes all track points in correct order" do
          doc = parse_gpx(gpx_content)
          track_points = extract_track_points(doc)

          expect(track_points.length).to eq(100)

          # Verify points are in correct order (latitude decreasing, longitude increasing)
          track_points.each_cons(2) do |pt1, pt2|
            expect(pt2[:lat]).to be <= pt1[:lat] # Moving south
            expect(pt2[:lon]).to be >= pt1[:lon] # Moving east
          end
        end

        it "validates as detailed route" do
          doc = parse_gpx(gpx_content)
          track_points = validate_detailed_route(doc, min_points: 100)

          expect(track_points.length).to eq(100)
        end
      end
    end

    context "with route containing special characters" do
      let(:route) do
        create(:route,
               starting_location: "Zürich, Switzerland",
               destination: "München, Germany",
               road_trip: road_trip,
               user: user)
      end

      it "properly escapes XML special characters" do
        gpx_content = exporter.generate
        doc = parse_gpx(gpx_content)

        # Should parse without errors even with special characters
        expect(doc.errors).to be_empty

        # Check that special characters are preserved
        metadata = doc.at_xpath("//gpx:metadata", gpx: "http://www.topografix.com/GPX/1/1")
        name = metadata.at_xpath("gpx:name", gpx: "http://www.topografix.com/GPX/1/1")

        expect(name.text).to include("Zürich")
        expect(name.text).to include("München")
      end
    end
  end

  describe "#generate_with_validation" do
    it "returns success with valid GPX" do
      result = exporter.generate_with_validation

      expect(result[:success]).to be true
      expect(result[:gpx]).not_to be_nil
      expect(result[:errors]).to be_empty
    end

    it "validates the generated GPX" do
      result = exporter.generate_with_validation

      # Use helper to validate the generated GPX
      doc = validate_gpx_structure(result[:gpx])
      expect(doc).not_to be_nil
    end

    context "with invalid GPX" do
      before do
        # Force an error in GPX generation
        allow(exporter).to receive(:generate).and_return("<invalid>not gpx</invalid>")
      end

      it "returns validation errors" do
        result = exporter.generate_with_validation

        expect(result[:success]).to be false
        expect(result[:errors]).not_to be_empty
        expect(result[:errors].first).to include("Missing GPX root element")
      end
    end
  end

  describe "integration with real route" do
    it "generates GPX that validates against the route" do
      gpx_content = exporter.generate

      # Use the route-specific validation helper
      doc = validate_route_gpx(gpx_content, route)
      expect(doc).not_to be_nil
    end
  end
end
