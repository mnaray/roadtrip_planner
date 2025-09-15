require 'webmock/rspec'

# Disable all real HTTP connections except localhost for Capybara
WebMock.disable_net_connect!(
  allow_localhost: true,
  allow: ['chromedriver.storage.googleapis.com', 'googlechromelabs.github.io']
)

RSpec.configure do |config|
  config.before(:each) do
    # Stub OSRM routing API - returns a simple route between two points
    stub_request(:get, /router\.project-osrm\.org\/route\/v1\/driving/).
      to_return(
        status: 200,
        body: lambda do |request|
          # Extract coordinates from the URL to create a realistic response
          uri = URI.parse(request.uri)
          coords = uri.path.split('/').last.split(';').map { |c| c.split(',').map(&:to_f) }

          # Generate a simple route with 4 points between start and end
          start_lon, start_lat = coords[0]
          end_lon, end_lat = coords[-1]

          route_coords = [
            [start_lon, start_lat],
            [start_lon * 0.7 + end_lon * 0.3, start_lat * 0.7 + end_lat * 0.3],
            [start_lon * 0.3 + end_lon * 0.7, start_lat * 0.3 + end_lat * 0.7],
            [end_lon, end_lat]
          ]

          {
            code: "Ok",
            routes: [{
              geometry: {
                type: "LineString",
                coordinates: route_coords
              },
              legs: [{
                summary: "",
                weight: 3600,
                duration: 3600,
                steps: [],
                distance: 350000
              }],
              weight_name: "routability",
              weight: 3600,
              duration: 3600,
              distance: 350000
            }],
            waypoints: coords.map do |lon, lat|
              {
                hint: "",
                distance: 4.1,
                name: "Street Name",
                location: [lon, lat]
              }
            end
          }.to_json
        end,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub Nominatim geocoding API
    stub_request(:get, /nominatim\.openstreetmap\.org\/search/).
      to_return(
        status: 200,
        body: lambda do |request|
          uri = URI.parse(request.uri)
          params = CGI.parse(uri.query)
          query = params['q']&.first || ''

          # Return appropriate coordinates based on location
          lat, lon = case query
          when /San Francisco/i
            [37.7749, -122.4194]
          when /Los Angeles/i
            [34.0522, -118.2437]
          when /New York/i
            [40.7128, -74.0060]
          when /Chicago/i
            [41.8781, -87.6298]
          when /Boston/i
            [42.3601, -71.0589]
          when /Zürich/i
            [47.3769, 8.5417]
          when /München|Munich/i
            [48.1351, 11.5820]
          else
            [0.0, 0.0]
          end

          [{
            place_id: 123456789,
            licence: "Data © OpenStreetMap contributors",
            osm_type: "node",
            osm_id: 123456789,
            boundingbox: [lat - 0.1, lat + 0.1, lon - 0.1, lon + 0.1],
            lat: lat.to_s,
            lon: lon.to_s,
            display_name: query,
            class: "place",
            type: "city",
            importance: 0.75
          }].to_json
        end,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub OpenRouteService API (for highway/toll avoidance) - GET requests
    stub_request(:get, /api\.openrouteservice\.org\/v2\/directions/).
      to_return(
        status: 200,
        body: lambda do |request|
          uri = URI.parse(request.uri)
          path_parts = uri.path.split('/')
          coords_str = path_parts.last
          coords = coords_str.split(',').map(&:to_f).each_slice(2).to_a

          start_lon, start_lat = coords[0]
          end_lon, end_lat = coords[-1]

          # Generate more points for highway avoidance route
          route_coords = [
            [start_lon, start_lat],
            [start_lon * 0.9 + end_lon * 0.1, start_lat * 0.9 + end_lat * 0.1],
            [start_lon * 0.7 + end_lon * 0.3, start_lat * 0.7 + end_lat * 0.3],
            [start_lon * 0.5 + end_lon * 0.5, start_lat * 0.5 + end_lat * 0.5],
            [start_lon * 0.3 + end_lon * 0.7, start_lat * 0.3 + end_lat * 0.7],
            [start_lon * 0.1 + end_lon * 0.9, start_lat * 0.1 + end_lat * 0.9],
            [end_lon, end_lat]
          ]

          {
            type: "FeatureCollection",
            features: [{
              type: "Feature",
              properties: {
                segments: [{
                  distance: 450000,
                  duration: 5400,
                  steps: []
                }],
                summary: {
                  distance: 450000,
                  duration: 5400
                },
                way_points: [0, route_coords.length - 1]
              },
              geometry: {
                type: "LineString",
                coordinates: route_coords
              }
            }],
            bbox: [
              [start_lon, start_lat].min,
              [start_lon, start_lat].min,
              [end_lon, end_lat].max,
              [end_lon, end_lat].max
            ],
            metadata: {
              attribution: "openrouteservice.org",
              service: "routing",
              timestamp: Time.now.to_i * 1000,
              query: {
                coordinates: coords,
                profile: "driving-car",
                format: "geojson"
              }
            }
          }.to_json
        end,
        headers: { 'Content-Type' => 'application/json' }
      )

    # Stub OpenRouteService API (for highway/toll avoidance) - POST requests
    stub_request(:post, /api\.openrouteservice\.org\/v2\/directions\/driving-car/).
      to_return(
        status: 200,
        body: lambda do |request|
          # Parse the JSON body to get coordinates
          begin
            body = JSON.parse(request.body)
            coords = body["coordinates"] || [[0.0, 0.0], [0.0, 0.0]]
          rescue
            coords = [[0.0, 0.0], [0.0, 0.0]]
          end

          start_lon, start_lat = coords[0]
          end_lon, end_lat = coords[-1]

          # Generate more points for highway avoidance route (longer route)
          route_coords = [
            [start_lon, start_lat],
            [start_lon * 0.9 + end_lon * 0.1, start_lat * 0.9 + end_lat * 0.1],
            [start_lon * 0.7 + end_lon * 0.3, start_lat * 0.7 + end_lat * 0.3],
            [start_lon * 0.5 + end_lon * 0.5, start_lat * 0.5 + end_lat * 0.5],
            [start_lon * 0.3 + end_lon * 0.7, start_lat * 0.3 + end_lat * 0.7],
            [start_lon * 0.1 + end_lon * 0.9, start_lat * 0.1 + end_lat * 0.9],
            [end_lon, end_lat]
          ]

          {
            type: "FeatureCollection",
            features: [{
              type: "Feature",
              properties: {
                segments: [{
                  distance: 450000,
                  duration: 5400,
                  steps: []
                }],
                summary: {
                  distance: 450000,
                  duration: 5400
                },
                way_points: [0, route_coords.length - 1]
              },
              geometry: {
                type: "LineString",
                coordinates: route_coords
              }
            }],
            bbox: [
              [start_lon, start_lat].min,
              [start_lon, start_lat].min,
              [end_lon, end_lat].max,
              [end_lon, end_lat].max
            ],
            metadata: {
              attribution: "openrouteservice.org",
              service: "routing",
              timestamp: Time.now.to_i * 1000,
              query: {
                coordinates: coords,
                profile: "driving-car",
                format: "geojson"
              }
            }
          }.to_json
        end,
        headers: { 'Content-Type' => 'application/json' }
      )
  end
end