class RoutesController < ApplicationController
  before_action :require_login, except: [ :route_data, :route_data_with_waypoints ]
  skip_before_action :verify_authenticity_token, only: [ :route_data, :route_data_with_waypoints ]
  before_action :set_road_trip, only: [ :new, :create ]
  before_action :set_route, only: [ :show, :edit, :update, :destroy, :map, :export_gpx, :edit_waypoints, :update_waypoints ]
  before_action :set_road_trip_for_route, only: [ :edit, :update ]
  before_action :set_route_for_confirmation, only: [ :confirm_route, :approve_route ]

  def new
    @route = @road_trip.routes.build
    session[:route_data] = nil
    render Routes::FormPageComponent.new(route: @route, road_trip: @road_trip, current_user: current_user)
  end

  def create
    @route = @road_trip.routes.build(route_create_params)
    @route.user = current_user

    session[:route_data] = {
      "road_trip_id" => @road_trip.id,
      "starting_location" => @route.starting_location,
      "destination" => @route.destination,
      "avoid_motorways" => @route.avoid_motorways
    }

    if @route.valid?(:location_only)
      redirect_to set_waypoints_path
    else
      render Routes::FormPageComponent.new(route: @route, road_trip: @road_trip, current_user: current_user),
             status: :unprocessable_content
    end
  end

  def show
    render Routes::MapComponent.new(route: @route, current_user: current_user)
  end

  def edit
    render Routes::FormPageComponent.new(route: @route, road_trip: @route.road_trip, current_user: current_user)
  end

  def update
    if @route.update(route_params)
      redirect_to @route.road_trip, notice: "Route was successfully updated."
    else
      render Routes::FormPageComponent.new(route: @route, road_trip: @route.road_trip, current_user: current_user),
             status: :unprocessable_content
    end
  end

  def destroy
    road_trip = @route.road_trip
    @route.destroy!
    redirect_to road_trip, notice: "Route was successfully deleted."
  end

  def confirm_route
    render Routes::ConfirmPageComponent.new(route_data: session[:route_data], current_user: current_user)
  end

  def approve_route
    route_data = session[:route_data]
    return redirect_to road_trips_path, alert: "No route data found." unless route_data

    road_trip = RoadTrip.find(route_data["road_trip_id"])

    # Check if user has access to this road trip
    unless road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this road trip."
      return
    end
    @route = road_trip.routes.build(
      starting_location: route_data["starting_location"],
      destination: route_data["destination"],
      datetime: params[:datetime],
      avoid_motorways: route_data["avoid_motorways"] || false,
      user: current_user
    )

    if @route.save
      # Create waypoints if they were provided in the session
      if route_data["waypoints"].present?
        route_data["waypoints"].each_with_index do |waypoint_data, index|
          @route.waypoints.create!(
            latitude: waypoint_data["latitude"],
            longitude: waypoint_data["longitude"],
            position: index + 1
          )
        end
      end

      session[:route_data] = nil
      redirect_to road_trip, notice: "Route was successfully added to your road trip."
    else
      Rails.logger.error "Route validation failed: #{@route.errors.full_messages}"
      render Routes::ConfirmPageComponent.new(route_data: route_data, route: @route, current_user: current_user),
             status: :unprocessable_content
    end
  end

  def map
    render Routes::MapComponent.new(route: @route, current_user: current_user)
  end

  def export_gpx
    gpx_generator = RouteGpxGenerator.new(@route)
    gpx_content = gpx_generator.generate

    filename = "route_#{@route.id}_#{@route.starting_location.parameterize}_to_#{@route.destination.parameterize}.gpx"

    send_data gpx_content,
              filename: filename,
              type: "application/gpx+xml",
              disposition: "attachment"
  end

  def edit_waypoints
    @waypoints = @route.waypoints.ordered
    render Routes::EditWaypointsComponent.new(route: @route, waypoints: @waypoints, current_user: current_user)
  end

  def update_waypoints
    # Handle waypoint updates
    waypoints_param = params[:waypoints]

    # Check if waypoints parameter is present and not empty
    if waypoints_param.present? && waypoints_param.strip != ""
      begin
        # Parse waypoints data
        waypoints_data = JSON.parse(waypoints_param)

        # Validate that waypoints_data is an array
        unless waypoints_data.is_a?(Array)
          raise ArgumentError, "Waypoints data must be an array"
        end

        # Use a transaction to ensure atomicity
        ActiveRecord::Base.transaction do
          # Delete existing waypoints
          @route.waypoints.destroy_all

          # Create new waypoints
          waypoints_data.each_with_index do |waypoint_data, index|
            # Validate required fields
            latitude = waypoint_data["latitude"]
            longitude = waypoint_data["longitude"]
            position = waypoint_data["position"] || (index + 1)
            name = waypoint_data["name"] || "Waypoint #{position}"

            # Validate latitude and longitude are present and numeric
            unless latitude.present? && longitude.present?
              raise ArgumentError, "Waypoint #{index + 1}: latitude and longitude are required"
            end

            # Convert to float and validate range
            lat_float = Float(latitude)
            lng_float = Float(longitude)

            unless lat_float.between?(-90, 90)
              raise ArgumentError, "Waypoint #{index + 1}: latitude must be between -90 and 90"
            end

            unless lng_float.between?(-180, 180)
              raise ArgumentError, "Waypoint #{index + 1}: longitude must be between -180 and 180"
            end

            @route.waypoints.create!(
              latitude: lat_float,
              longitude: lng_float,
              position: position,
              name: name
            )
          end
        end

        redirect_to @route.road_trip, notice: "Waypoints updated successfully."
      rescue JSON::ParserError => e
        Rails.logger.error "JSON parsing error: #{e.message}"
        redirect_to edit_route_waypoints_path(@route), alert: "Invalid waypoints data format."
      rescue ArgumentError => e
        Rails.logger.error "Waypoint validation error: #{e.message}"
        redirect_to edit_route_waypoints_path(@route), alert: e.message
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Failed to save waypoint: #{e.message}"
        redirect_to edit_route_waypoints_path(@route), alert: "Failed to save waypoints: #{e.message}"
      rescue => e
        Rails.logger.error "Unexpected error updating waypoints: #{e.message}"
        Rails.logger.error e.backtrace.join("\n")
        redirect_to edit_route_waypoints_path(@route), alert: "An unexpected error occurred while updating waypoints."
      end
    else
      # If no waypoints provided or empty string, clear all existing waypoints
      @route.waypoints.destroy_all
      redirect_to @route.road_trip, notice: "All waypoints removed."
    end
  end

  # API endpoint for map route calculations (avoids CORS issues)
  def route_data
    start_lat = params[:start_lat].to_f
    start_lon = params[:start_lon].to_f
    end_lat = params[:end_lat].to_f
    end_lon = params[:end_lon].to_f
    avoid_motorways = params[:avoid_motorways] == "true"

    if start_lat == 0 || start_lon == 0 || end_lat == 0 || end_lon == 0
      render json: { error: "Invalid coordinates" }, status: :bad_request
      return
    end

    begin
      if avoid_motorways
        # Use OpenRouteService for highway avoidance
        route_feature = fetch_openrouteservice_route([ start_lat, start_lon ], [ end_lat, end_lon ])

        if route_feature
          render json: route_feature
        else
          render json: { error: "Highway avoidance routing failed" }, status: :service_unavailable
        end
      else
        # Use OSRM for normal routing
        route_data = fetch_osrm_route([ start_lat, start_lon ], [ end_lat, end_lon ])

        if route_data
          render json: route_data
        else
          render json: { error: "Normal routing failed" }, status: :service_unavailable
        end
      end
    rescue => e
      Rails.logger.error "Route data API error: #{e.message}"
      render json: { error: "Route calculation failed" }, status: :internal_server_error
    end
  end

  # API endpoint for waypoint route calculations (avoids CORS issues)
  def route_data_with_waypoints
    coordinates = params[:coordinates]
    avoid_motorways = params[:avoid_motorways] == true || params[:avoid_motorways] == "true"

    unless coordinates.is_a?(Array) && coordinates.length >= 2
      render json: { error: "Invalid coordinates array" }, status: :bad_request
      return
    end

    begin
      if avoid_motorways
        # Use OpenRouteService for highway avoidance with waypoints
        route_feature = fetch_openrouteservice_route_with_waypoints(coordinates)

        if route_feature
          render json: route_feature
        else
          render json: { error: "Highway avoidance waypoint routing failed" }, status: :service_unavailable
        end
      else
        # Use OSRM for normal routing with waypoints
        route_data = fetch_osrm_route_with_waypoints(coordinates)

        if route_data
          render json: route_data
        else
          render json: { error: "Normal waypoint routing failed" }, status: :service_unavailable
        end
      end
    rescue => e
      Rails.logger.error "Waypoint route data API error: #{e.message}"
      render json: { error: "Waypoint route calculation failed" }, status: :internal_server_error
    end
  end

  private

  def set_road_trip
    @road_trip = RoadTrip.find(params[:road_trip_id])

    # Check if user has access (is owner or participant)
    unless @road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this road trip."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Road trip not found."
  end

  def set_route
    @route = Route.find(params[:id])

    # Check if user has access to the road trip containing this route
    unless @route.road_trip.can_access?(current_user)
      redirect_to road_trips_path, alert: "You don't have access to this route."
    end
  rescue ActiveRecord::RecordNotFound
    redirect_to road_trips_path, alert: "Route not found."
  end

  def set_road_trip_for_route
    @road_trip = @route.road_trip
  end

  def set_route_for_confirmation
    return if session[:route_data]
    redirect_to road_trips_path, alert: "No route data found."
  end

  def route_create_params
    params.require(:route).permit(:starting_location, :destination, :avoid_motorways)
  end

  def route_params
    params.require(:route).permit(:starting_location, :destination, :datetime, :avoid_motorways)
  end

  def fetch_openrouteservice_route(start_coords, end_coords)
    require "net/http"
    require "json"
    require "uri"

    start_lat, start_lon = start_coords
    end_lat, end_lon = end_coords

    uri = URI("https://api.openrouteservice.org/v2/directions/driving-car/geojson")

    request_body = {
      coordinates: [ [ start_lon, start_lat ], [ end_lon, end_lat ] ],
      options: {
        avoid_features: [ "highways", "tollways" ]
      }
    }

    api_key = ENV["OPENROUTESERVICE_API_KEY"] || Rails.application.credentials.dig(:openrouteservice, :api_key)

    return nil unless api_key

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = api_key
      request.body = request_body.to_json

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        Rails.logger.info "OpenRouteService response structure: #{data.keys}"

        if data["features"] && data["features"].any?
          # OpenRouteService returns GeoJSON with features array
          feature = data["features"].first
          Rails.logger.info "OpenRouteService feature: type=#{feature['type']}, geometry=#{feature['geometry'] ? 'present' : 'missing'}"
          return {
            type: "Feature",
            geometry: feature["geometry"],
            properties: {
              segments: [ {
                distance: feature["properties"]["segments"].first["distance"],
                duration: feature["properties"]["segments"].first["duration"]
              } ]
            }
          }
        elsif data["routes"] && data["routes"].any?
          # Fallback for different response format
          route = data["routes"].first
          Rails.logger.info "OpenRouteService route: geometry=#{route['geometry'] ? 'present' : 'missing'}"
          return {
            type: "Feature",
            geometry: route["geometry"],
            properties: {
              segments: [ {
                distance: route["summary"]["distance"],
                duration: route["summary"]["duration"]
              } ]
            }
          }
        else
          Rails.logger.warn "OpenRouteService response missing expected data: #{data.keys}"
        end
      else
        Rails.logger.error "OpenRouteService API error: #{response.code} - #{response.body}"
      end
    rescue => e
      Rails.logger.error "OpenRouteService routing error: #{e.message}"
    end

    nil
  end

  def fetch_osrm_route(start_coords, end_coords)
    require "net/http"
    require "json"
    require "uri"

    start_lat, start_lon = start_coords
    end_lat, end_lon = end_coords

    url = "https://router.project-osrm.org/route/v1/driving/#{start_lon},#{start_lat};#{end_lon},#{end_lat}?overview=full&geometries=geojson"

    begin
      response = Net::HTTP.get_response(URI(url))

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)

        if data && data["routes"] && data["routes"].any?
          route = data["routes"].first
          return {
            type: "Feature",
            geometry: route["geometry"],
            properties: {
              segments: [ {
                distance: route["distance"],
                duration: route["duration"]
              } ]
            }
          }
        end
      else
        Rails.logger.error "OSRM API error: #{response.code} - #{response.body}"
      end
    rescue => e
      Rails.logger.error "OSRM routing error: #{e.message}"
    end

    nil
  end

  def fetch_openrouteservice_route_with_waypoints(coordinates)
    require "net/http"
    require "json"
    require "uri"

    uri = URI("https://api.openrouteservice.org/v2/directions/driving-car/geojson")

    request_body = {
      coordinates: coordinates,
      options: {
        avoid_features: [ "highways", "tollways" ]
      }
    }

    api_key = ENV["OPENROUTESERVICE_API_KEY"] || Rails.application.credentials.dig(:openrouteservice, :api_key)

    return nil unless api_key

    begin
      http = Net::HTTP.new(uri.host, uri.port)
      http.use_ssl = true

      request = Net::HTTP::Post.new(uri)
      request["Content-Type"] = "application/json"
      request["Authorization"] = api_key
      request.body = request_body.to_json

      response = http.request(request)

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)
        Rails.logger.info "OpenRouteService waypoint response structure: #{data.keys}"

        if data["features"] && data["features"].any?
          # OpenRouteService returns GeoJSON with features array
          feature = data["features"].first
          Rails.logger.info "OpenRouteService waypoint feature: type=#{feature['type']}, geometry=#{feature['geometry'] ? 'present' : 'missing'}"
          return {
            type: "Feature",
            geometry: feature["geometry"],
            properties: {
              segments: [ {
                distance: feature["properties"]["segments"].first["distance"],
                duration: feature["properties"]["segments"].first["duration"]
              } ]
            }
          }
        elsif data["routes"] && data["routes"].any?
          # Fallback for different response format
          route = data["routes"].first
          Rails.logger.info "OpenRouteService waypoint route: geometry=#{route['geometry'] ? 'present' : 'missing'}"
          return {
            type: "Feature",
            geometry: route["geometry"],
            properties: {
              segments: [ {
                distance: route["summary"]["distance"],
                duration: route["summary"]["duration"]
              } ]
            }
          }
        else
          Rails.logger.warn "OpenRouteService waypoint response missing expected data: #{data.keys}"
        end
      else
        Rails.logger.error "OpenRouteService waypoint API error: #{response.code} - #{response.body}"
      end
    rescue => e
      Rails.logger.error "OpenRouteService waypoint routing error: #{e.message}"
    end

    nil
  end

  def fetch_osrm_route_with_waypoints(coordinates)
    require "net/http"
    require "json"
    require "uri"

    # Convert coordinates to OSRM format: lon,lat;lon,lat;...
    coords_string = coordinates.map { |coord| "#{coord[0]},#{coord[1]}" }.join(";")

    url = "https://router.project-osrm.org/route/v1/driving/#{coords_string}?overview=full&geometries=geojson"

    begin
      response = Net::HTTP.get_response(URI(url))

      if response.is_a?(Net::HTTPSuccess)
        data = JSON.parse(response.body)

        if data && data["routes"] && data["routes"].any?
          route = data["routes"].first
          return {
            type: "Feature",
            geometry: route["geometry"],
            properties: {
              segments: [ {
                distance: route["distance"],
                duration: route["duration"]
              } ]
            }
          }
        end
      else
        Rails.logger.error "OSRM waypoint API error: #{response.code} - #{response.body}"
      end
    rescue => e
      Rails.logger.error "OSRM waypoint routing error: #{e.message}"
    end

    nil
  end
end
