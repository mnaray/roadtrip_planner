require 'rails_helper'

RSpec.describe RouteDistanceCalculator do
  let(:start_location) { "New York, NY" }
  let(:destination) { "Boston, MA" }

  describe '#initialize' do
    it 'initializes with start and destination locations' do
      calculator = described_class.new(start_location, destination)
      expect(calculator).to be_present
    end

    it 'accepts waypoints parameter' do
      waypoints = [ { latitude: 40.7128, longitude: -74.0060 } ]
      calculator = described_class.new(start_location, destination, waypoints)
      expect(calculator).to be_present
    end

    it 'defaults waypoints to empty array' do
      calculator = described_class.new(start_location, destination)
      expect(calculator.instance_variable_get(:@waypoints)).to eq([])
    end

    it 'accepts avoid_motorways parameter' do
      calculator = described_class.new(start_location, destination, [], avoid_motorways: true)
      expect(calculator.instance_variable_get(:@avoid_motorways)).to be true
    end

    it 'defaults avoid_motorways to false' do
      calculator = described_class.new(start_location, destination)
      expect(calculator.instance_variable_get(:@avoid_motorways)).to be false
    end
  end

  describe '#calculate' do
    let(:calculator) { described_class.new(start_location, destination) }

    context 'without waypoints' do
      before do
        allow(calculator).to receive(:geocode).with(start_location)
                                              .and_return([ 40.7128, -74.0060 ]) # NYC coords
        allow(calculator).to receive(:geocode).with(destination)
                                              .and_return([ 42.3601, -71.0589 ]) # Boston coords
        allow(calculator).to receive(:fetch_route_data_osrm)
                                .and_return({ distance: 300000, duration: 14400 }) # 300km, 4h
      end

      it 'calculates distance and duration without waypoints' do
        result = calculator.calculate

        expect(result[:distance]).to eq(300000) # meters (300 km)
        expect(result[:duration]).to eq(4.0)    # hours
      end
    end

    context 'with waypoints' do
      let(:waypoints) { [ create(:waypoint, latitude: 41.4993, longitude: -81.6944) ] } # Cleveland
      let(:calculator) { described_class.new(start_location, destination, waypoints) }

      before do
        allow(calculator).to receive(:geocode).with(start_location)
                                              .and_return([ 40.7128, -74.0060 ]) # NYC coords
        allow(calculator).to receive(:geocode).with(destination)
                                              .and_return([ 42.3601, -71.0589 ]) # Boston coords
        allow(calculator).to receive(:calculate_with_waypoints_from_coordinates)
                                .and_return({ distance: 450000, duration: 21600 }) # 450km, 6h
      end

      it 'calculates route with waypoints' do
        result = calculator.calculate

        expect(result[:distance]).to eq(450000) # meters (450 km, longer due to waypoint)
        expect(result[:duration]).to eq(6.0)    # hours (longer due to waypoint)
      end
    end

    context 'when geocoding fails' do
      before do
        allow(calculator).to receive(:geocode).and_return(nil)
      end

      it 'returns nil values' do
        result = calculator.calculate

        expect(result[:distance]).to be_nil
        expect(result[:duration]).to be_nil
      end
    end

    context 'when routing API fails' do
      before do
        allow(calculator).to receive(:geocode).with(start_location)
                                              .and_return([ 40.7128, -74.0060 ])
        allow(calculator).to receive(:geocode).with(destination)
                                              .and_return([ 42.3601, -71.0589 ])
        allow(calculator).to receive(:fetch_route_data_osrm).and_return(nil)
        allow(calculator).to receive(:calculate_straight_line_estimates)
                                .and_return({ distance: 250000, duration: 12000 })
      end

      it 'falls back to straight-line calculations' do
        result = calculator.calculate

        expect(result[:distance]).to eq(250000) # meters (250 km)
        expect(result[:duration]).to eq(3.33)   # hours (rounded)
      end
    end
  end

  describe '#calculate_with_waypoints_from_coordinates' do
    let(:calculator) { described_class.new(start_location, destination) }
    let(:start_coords) { [ 40.7128, -74.0060 ] } # NYC
    let(:waypoint_coords) { [ [ 41.4993, -81.6944 ] ] } # Cleveland
    let(:end_coords) { [ 42.3601, -71.0589 ] } # Boston

    context 'when OSRM waypoint routing succeeds' do
      before do
        allow(calculator).to receive(:fetch_route_data_osrm_with_waypoints)
                                .and_return({ distance: 500000, duration: 25200 })
      end

      it 'uses OSRM waypoint routing' do
        result = calculator.send(:calculate_with_waypoints_from_coordinates,
                                start_coords, waypoint_coords, end_coords)

        expect(result[:distance]).to eq(500000)
        expect(result[:duration]).to eq(25200)
      end
    end

    context 'when OSRM waypoint routing fails' do
      before do
        allow(calculator).to receive(:fetch_route_data_osrm_with_waypoints).and_return(nil)
        allow(calculator).to receive(:calculate_multi_segment_route)
                                .and_return({ distance: 480000, duration: 24000 })
      end

      it 'falls back to multi-segment routing' do
        result = calculator.send(:calculate_with_waypoints_from_coordinates,
                                start_coords, waypoint_coords, end_coords)

        expect(result[:distance]).to eq(480000)
        expect(result[:duration]).to eq(24000)
      end
    end
  end

  describe 'waypoint format handling' do
    let(:route) { create(:route) }

    context 'with ActiveRecord waypoint models' do
      let(:waypoints) { [ create(:waypoint, route: route, latitude: 41.4993, longitude: -81.6944) ] }
      let(:calculator) { described_class.new(start_location, destination, waypoints) }

      before do
        allow(calculator).to receive(:geocode).with(start_location)
                                              .and_return([ 40.7128, -74.0060 ])
        allow(calculator).to receive(:geocode).with(destination)
                                              .and_return([ 42.3601, -71.0589 ])
        allow(calculator).to receive(:calculate_with_waypoints_from_coordinates)
                                .and_return({ distance: 450000, duration: 21600 })
      end

      it 'extracts coordinates from waypoint models' do
        result = calculator.calculate
        expect(result[:distance]).to eq(450000) # meters (450 km)
      end
    end

    context 'with hash waypoints' do
      let(:waypoints) { [ { latitude: 41.4993, longitude: -81.6944 } ] }
      let(:calculator) { described_class.new(start_location, destination, waypoints) }

      before do
        allow(calculator).to receive(:geocode).with(start_location)
                                              .and_return([ 40.7128, -74.0060 ])
        allow(calculator).to receive(:geocode).with(destination)
                                              .and_return([ 42.3601, -71.0589 ])
        allow(calculator).to receive(:calculate_with_waypoints_from_coordinates)
                                .and_return({ distance: 450000, duration: 21600 })
      end

      it 'handles hash format waypoints' do
        result = calculator.calculate
        expect(result[:distance]).to eq(450000) # meters (450 km)
      end
    end

    context 'with coordinate array waypoints' do
      let(:waypoints) { [ [ 41.4993, -81.6944 ] ] }
      let(:calculator) { described_class.new(start_location, destination, waypoints) }

      before do
        allow(calculator).to receive(:geocode).with(start_location)
                                              .and_return([ 40.7128, -74.0060 ])
        allow(calculator).to receive(:geocode).with(destination)
                                              .and_return([ 42.3601, -71.0589 ])
        allow(calculator).to receive(:calculate_with_waypoints_from_coordinates)
                                .and_return({ distance: 450000, duration: 21600 })
      end

      it 'handles coordinate array format waypoints' do
        result = calculator.calculate
        expect(result[:distance]).to eq(450000) # meters (450 km)
      end
    end
  end

  describe 'avoid_motorways functionality' do
    it 'stores avoid_motorways setting correctly' do
      calculator_enabled = described_class.new(start_location, destination, [], avoid_motorways: true)
      expect(calculator_enabled.instance_variable_get(:@avoid_motorways)).to be true

      calculator_disabled = described_class.new(start_location, destination, [], avoid_motorways: false)
      expect(calculator_disabled.instance_variable_get(:@avoid_motorways)).to be false
    end

    it 'defaults avoid_motorways to false when not specified' do
      calculator = described_class.new(start_location, destination, [])
      expect(calculator.instance_variable_get(:@avoid_motorways)).to be false
    end
  end
end
