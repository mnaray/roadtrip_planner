# Stub external API calls to avoid network requests in tests
RSpec.configure do |config|
  config.before(:each) do
    # Stub RouteDistanceCalculator API calls
    allow_any_instance_of(RouteDistanceCalculator).to receive(:geocode) do |_, location|
      case location
      when /San Francisco/i
        [37.7749, -122.4194]
      when /Los Angeles/i
        [34.0522, -118.2437]
      when /New York/i
        [40.7128, -74.0060]
      when /Chicago/i
        [41.8781, -87.6298]
      else
        [0.0, 0.0]
      end
    end
    
    allow_any_instance_of(RouteDistanceCalculator).to receive(:fetch_route_data_osrm).and_return({
      distance: 100000,  # 100 km in meters
      duration: 7200     # 2 hours in seconds
    })
    
    # Stub GPX service methods to return valid XML
    allow_any_instance_of(RouteGpxGenerator).to receive(:generate).and_return(
      '<?xml version="1.0" encoding="UTF-8"?><gpx version="1.1"><trk><name>Test Route</name></trk></gpx>'
    )
    
    allow_any_instance_of(RouteGpxExporter).to receive(:generate).and_return(
      '<?xml version="1.0" encoding="UTF-8"?><gpx version="1.1"><trk><name>Exported Route</name></trk></gpx>'
    )
  end
end