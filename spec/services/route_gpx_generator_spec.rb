require "rails_helper"
require "support/gpx_helpers"

RSpec.describe RouteGpxGenerator, type: :service do
  let(:user) { create(:user) }
  let(:road_trip) { create(:road_trip, user: user) }
  let(:route) do
    create(:route,
           starting_location: "New York, NY",
           destination: "Boston, MA",
           datetime: 1.day.from_now,
           road_trip: road_trip,
           user: user)
  end

  let(:generator) { described_class.new(route) }

  describe "#generate" do
    context "with valid route" do
      before do
        # Mock geocoding to return consistent coordinates
        allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).with("New York, NY").and_return([40.7128, -74.0060])
        allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).with("Boston, MA").and_return([42.3601, -71.0589])
      end

      let(:gpx_content) { generator.generate }

      it "generates valid GPX XML" do
        # Basic structure validation
        doc = parse_gpx(gpx_content)
        expect(doc).not_to be_nil
        expect(doc.errors).to be_empty
      end

      it "has correct GPX root element" do
        doc = parse_gpx(gpx_content)
        root = doc.root

        expect(root.name).to eq("gpx")
        expect(root["version"]).to eq("1.1")
        expect(root["creator"]).to eq("Road Trip Planner")
        expect(root.namespace.href).to eq("http://www.topografix.com/GPX/1/1")
      end

      it "includes metadata section" do
        doc = parse_gpx(gpx_content)
        metadata = doc.at_xpath("//xmlns:metadata")

        expect(metadata).not_to be_nil

        name = metadata.at_xpath("xmlns:name")
        expect(name.text).to include(route.starting_location)
        expect(name.text).to include(route.destination)

        desc = metadata.at_xpath("xmlns:desc")
        expect(desc).not_to be_nil

        time = metadata.at_xpath("xmlns:time")
        expect(time.text).to eq(route.datetime.iso8601)
      end

      context "when OSRM provides route data" do
        let(:mock_route_data) do
          {
            geometry: {
              "coordinates" => [
                [ -74.0060, 40.7128 ], # New York
                [ -73.9900, 40.7500 ], # Intermediate
                [ -73.9700, 40.7800 ], # Intermediate
                [ -71.0589, 42.3601 ]  # Boston
              ]
            },
            distance: 350000, # meters
            duration: 14400   # seconds
          }
        end

        before do
          # Mock geocoding
          allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).with("New York, NY").and_return([40.7128, -74.0060])
          allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).with("Boston, MA").and_return([42.3601, -71.0589])
          allow_any_instance_of(RouteGpxGenerator).to receive(:fetch_route_data).and_return(mock_route_data)
        end

        it "includes waypoints for start and destination" do
          doc = parse_gpx(gpx_content)
          waypoints = doc.xpath("//xmlns:wpt")

          expect(waypoints.length).to eq(2)

          # Check start waypoint
          start_wpt = waypoints.first
          expect(start_wpt["lat"].to_f).to be_within(0.001).of(40.7128)
          expect(start_wpt["lon"].to_f).to be_within(0.001).of(-74.0060)

          name = start_wpt.at_xpath("xmlns:name")
          expect(name.text).to include("Start")
          expect(name.text).to include(route.starting_location)

          # Check end waypoint
          end_wpt = waypoints.last
          expect(end_wpt["lat"].to_f).to be_within(0.001).of(42.3601)
          expect(end_wpt["lon"].to_f).to be_within(0.001).of(-71.0589)

          name = end_wpt.at_xpath("xmlns:name")
          expect(name.text).to include("Destination")
          expect(name.text).to include(route.destination)
        end

        it "includes track with all route points" do
          doc = parse_gpx(gpx_content)

          track = doc.at_xpath("//xmlns:trk")
          expect(track).not_to be_nil

          # Check track metadata
          track_name = track.at_xpath("xmlns:name")
          expect(track_name.text).to include("Route:")
          expect(track_name.text).to include(route.starting_location)
          expect(track_name.text).to include(route.destination)

          track_desc = track.at_xpath("xmlns:desc")
          expect(track_desc.text).to include("Distance: 350.0 km")
          expect(track_desc.text).to include("Estimated duration: 4.0 hours")
        end

        it "includes all track points in correct order" do
          doc = parse_gpx(gpx_content)

          track_points = doc.xpath("//xmlns:trkpt")
          expect(track_points.length).to eq(4)

          # Verify coordinates match the mock data
          expected_coords = [
            [ 40.7128, -74.0060 ],
            [ 40.7500, -73.9900 ],
            [ 40.7800, -73.9700 ],
            [ 42.3601, -71.0589 ]
          ]

          track_points.each_with_index do |pt, i|
            expect(pt["lat"].to_f).to be_within(0.001).of(expected_coords[i][0])
            expect(pt["lon"].to_f).to be_within(0.001).of(expected_coords[i][1])
          end
        end

        it "validates using GPX helpers" do
          doc = validate_gpx_structure(gpx_content, min_track_points: 4)

          # Extract and verify track points
          track_points = extract_track_points(doc)
          expect(track_points.length).to eq(4)

          # Verify all coordinates are valid
          track_points.each do |pt|
            validate_coordinate(pt[:lat], pt[:lon])
          end
        end
      end

      context "when OSRM is unavailable" do
        before do
          # Mock geocoding
          allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).with("New York, NY").and_return([40.7128, -74.0060])
          allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).with("Boston, MA").and_return([42.3601, -71.0589])
          allow_any_instance_of(RouteGpxGenerator).to receive(:fetch_route_data).and_return(nil)
        end

        it "falls back to waypoint-only GPX" do
          doc = parse_gpx(gpx_content)

          # Should have waypoints
          waypoints = doc.xpath("//xmlns:wpt")
          expect(waypoints.length).to eq(2)

          # Should have route element instead of track
          route_elem = doc.at_xpath("//xmlns:rte")
          expect(route_elem).not_to be_nil

          # Route should have waypoints
          route_points = route_elem.xpath("xmlns:rtept")
          expect(route_points.length).to eq(2)
        end

        it "includes descriptive message about fallback" do
          doc = parse_gpx(gpx_content)

          route_elem = doc.at_xpath("//xmlns:rte")
          desc = route_elem.at_xpath("xmlns:desc")

          expect(desc.text).to include("Direct waypoint route")
        end
      end
    end

    context "with route having actual distance and duration" do
      before do
        route.update(distance: 250.5, duration: 3.75)
      end

      let(:mock_route_data) do
        {
          geometry: {
            "coordinates" => [
              [ -74.0060, 40.7128 ],
              [ -71.0589, 42.3601 ]
            ]
          },
          distance: route.distance * 1000,
          duration: route.duration * 3600
        }
      end

      before do
        # Mock geocoding
        allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).with("New York, NY").and_return([40.7128, -74.0060])
        allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).with("Boston, MA").and_return([42.3601, -71.0589])
        allow_any_instance_of(RouteGpxGenerator).to receive(:fetch_route_data).and_return(mock_route_data)
      end

      it "includes actual distance and duration in track description" do
        gpx_content = generator.generate
        doc = parse_gpx(gpx_content)

        track = doc.at_xpath("//xmlns:trk")
        desc = track.at_xpath("xmlns:desc")

        expect(desc.text).to include("Distance: 250.5 km")
        expect(desc.text).to include("duration: 3.8 hours")
      end
    end

    context "error handling" do
      context "when geocoding fails" do
        before do
          allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).and_return(nil)
        end

        it "returns fallback GPX" do
          gpx_content = generator.generate
          doc = parse_gpx(gpx_content)

          # Should still have valid GPX structure
          expect(doc.root.name).to eq("gpx")

          # Should have metadata with error indication
          metadata = doc.at_xpath("//xmlns:metadata")
          desc = metadata.at_xpath("xmlns:desc")

          expect(desc.text).to include("temporarily unavailable")
        end
      end

      context "when route has invalid coordinates" do
        let(:route) do
          create(:route,
                 starting_location: "Invalid Location XYZ",
                 destination: "Another Invalid Place",
                 road_trip: road_trip,
                 user: user)
        end

        before do
          allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).and_return(nil)
        end

        it "still generates valid GPX structure" do
          gpx_content = generator.generate
          expect { parse_gpx(gpx_content) }.not_to raise_error
        end
      end
    end
  end

  describe "comparison with RouteGpxExporter" do
    let(:exporter) { RouteGpxExporter.new(route) }

    before do
      # Mock geocoding for both services
      allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).with("New York, NY").and_return([40.7128, -74.0060])
      allow_any_instance_of(RouteGpxGenerator).to receive(:geocode).with("Boston, MA").and_return([42.3601, -71.0589])
      # Mock route data for generator (exporter doesn't fetch external data)
      allow_any_instance_of(RouteGpxGenerator).to receive(:fetch_route_data).and_return({
        geometry: {
          "coordinates" => [
            [ -74.0060, 40.7128 ],
            [ -71.0589, 42.3601 ]
          ]
        },
        distance: 350000,
        duration: 14400
      })
    end

    it "both services generate valid GPX" do
      generator_gpx = generator.generate
      exporter_gpx = exporter.generate

      # Both should validate
      generator_doc = validate_gpx_structure(generator_gpx)
      exporter_doc = validate_gpx_structure(exporter_gpx)

      expect(generator_doc).not_to be_nil
      expect(exporter_doc).not_to be_nil
    end

    it "both include same route endpoints" do
      generator_gpx = generator.generate
      exporter_gpx = exporter.generate

      generator_waypoints = extract_waypoints(parse_gpx(generator_gpx))
      exporter_waypoints = extract_waypoints(parse_gpx(exporter_gpx))

      # Both should have waypoints for start and end
      expect(generator_waypoints.length).to be >= 2
      expect(exporter_waypoints.length).to be >= 2
    end
  end
end
