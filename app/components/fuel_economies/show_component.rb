class FuelEconomies::ShowComponent < ApplicationComponent
  def initialize(route:, current_user:)
    @route = route
    @current_user = current_user
    @road_trip = @route.road_trip
  end

  def view_template
    render ApplicationLayout.new(title: "Fuel Economy Calculator - #{@route.starting_location} to #{@route.destination}", current_user: @current_user) do
      div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8" do
        # Header with breadcrumb
        div class: "mb-8" do
          # Breadcrumb
          nav class: "flex mb-4", aria_label: "Breadcrumb" do
            ol class: "flex items-center space-x-4" do
              li do
                link_to road_trips_path, class: "text-blue-600 hover:text-blue-800 text-sm font-medium" do
                  "My Road Trips"
                end
              end
              li do
                svg_icon path_d: "M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z",
                         class: "w-4 h-4 text-gray-400",
                         fill: "currentColor",
                         fill_rule: "evenodd",
                         clip_rule: "evenodd",
                         viewBox: "0 0 20 20"
              end
              li do
                link_to road_trip_path(@road_trip), class: "text-blue-600 hover:text-blue-800 text-sm font-medium" do
                  @road_trip.name
                end
              end
              li do
                svg_icon path_d: "M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z",
                         class: "w-4 h-4 text-gray-400",
                         fill: "currentColor",
                         fill_rule: "evenodd",
                         clip_rule: "evenodd",
                         viewBox: "0 0 20 20"
              end
              li do
                link_to route_path(@route), class: "text-blue-600 hover:text-blue-800 text-sm font-medium" do
                  "Route: #{@route.starting_location} → #{@route.destination}"
                end
              end
              li do
                svg_icon path_d: "M7.293 14.707a1 1 0 010-1.414L10.586 10 7.293 6.707a1 1 0 011.414-1.414l4 4a1 1 0 010 1.414l-4 4a1 1 0 01-1.414 0z",
                         class: "w-4 h-4 text-gray-400",
                         fill: "currentColor",
                         fill_rule: "evenodd",
                         clip_rule: "evenodd",
                         viewBox: "0 0 20 20"
              end
              li class: "text-sm font-medium text-gray-900" do
                "Fuel Economy"
              end
            end
          end

          # Page header
          div class: "flex justify-between items-center" do
            div do
              h1 class: "text-3xl font-bold text-gray-900" do
                "Fuel Economy Calculator"
              end
              p class: "mt-1 text-sm text-gray-600" do
                "Calculate fuel costs and consumption for your route"
              end
            end

            # Back button
            link_to route_path(@route),
                    class: "inline-flex items-center px-3 py-2 border border-gray-300 text-sm font-medium rounded-md text-gray-700 bg-white hover:bg-gray-50 focus:outline-none focus:ring-2 focus:ring-blue-500 focus:ring-offset-2" do
              svg_icon path_d: "M7 16l-4-4m0 0l4-4m-4 4h18",
                       class: "w-4 h-4 mr-1.5",
                       stroke_linecap: "round",
                       stroke_linejoin: "round",
                       stroke_width: "2"
              span { "Back to Route" }
            end
          end
        end

        # Route Information Card
        div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6 mb-6" do
          h2 class: "text-lg font-semibold text-gray-900 mb-4" do
            "Route Information"
          end

          div class: "grid grid-cols-1 md:grid-cols-3 gap-4" do
            div do
              div class: "text-sm font-medium text-gray-500 mb-1" do
                "From"
              end
              div class: "text-base font-semibold text-gray-900" do
                @route.starting_location
              end
            end

            div do
              div class: "text-sm font-medium text-gray-500 mb-1" do
                "To"
              end
              div class: "text-base font-semibold text-gray-900" do
                @route.destination
              end
            end

            div do
              div class: "text-sm font-medium text-gray-500 mb-1" do
                "Distance"
              end
              div class: "text-base font-semibold text-gray-900" do
                if @route.distance_in_km
                  "#{@route.distance_in_km.round} km"
                else
                  "Distance not available"
                end
              end
            end
          end
        end

        # Fuel Economy Calculator
        div class: "bg-white rounded-lg shadow-sm border border-gray-200 p-6",
            data: {
              controller: "fuel-economy",
              fuel_economy_distance_value: @route.distance_in_km || 0
            } do
          h2 class: "text-lg font-semibold text-gray-900 mb-6" do
            "Fuel Cost Calculator"
          end

          # Vehicle Selection for Fuel Data
          if @road_trip.has_vehicles?
            div class: "mb-6 p-4 bg-green-50 border border-green-200 rounded-lg" do
              h3 class: "text-sm font-medium text-green-800 mb-3" do
                "Select Vehicle for Fuel Data"
              end

              div class: "space-y-2" do
                @road_trip.all_selected_vehicles.each_with_index do |selection, index|
                  vehicle = selection[:vehicle]
                  user = selection[:user]
                  next unless vehicle.has_fuel_consumption?

                  div class: "flex items-center space-x-3" do
                    input type: "radio",
                          id: "vehicle_#{vehicle.id}",
                          name: "vehicle_selector",
                          value: vehicle.fuel_consumption,
                          checked: index == 0,
                          class: "h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300",
                          data: {
                            action: "change->fuel-economy#updateFromVehicle",
                            fuel_consumption: vehicle.fuel_consumption,
                            passenger_count: vehicle.passenger_count || 1
                          }

                    label for: "vehicle_#{vehicle.id}", class: "flex items-center space-x-2 cursor-pointer" do
                      svg_icon path_d: vehicle_icon_path(vehicle.vehicle_type),
                               class: "h-5 w-5 text-gray-500"
                      div do
                        span class: "text-sm font-medium text-gray-900" do
                          "#{vehicle.display_name} (#{user.username})"
                        end
                        div class: "text-xs text-gray-600" do
                          parts = []
                          parts << "#{vehicle.fuel_consumption}L/100km" if vehicle.fuel_consumption.present?
                          parts << "#{vehicle.passenger_count} passengers" if vehicle.passenger_count.present?
                          parts.join(" • ")
                        end
                      end
                    end
                  end
                end

                # Manual entry option
                div class: "flex items-center space-x-3" do
                  input type: "radio",
                        id: "vehicle_manual",
                        name: "vehicle_selector",
                        value: "manual",
                        checked: !@road_trip.all_selected_vehicles.any? { |s| s[:vehicle].has_fuel_consumption? },
                        class: "h-4 w-4 text-green-600 focus:ring-green-500 border-gray-300",
                        data: { action: "change->fuel-economy#enableManualEntry" }

                  label for: "vehicle_manual", class: "text-sm font-medium text-gray-900 cursor-pointer" do
                    "Enter manually"
                  end
                end
              end
            end
          end

          # Input Fields
          div class: "space-y-4 mb-6" do
            # Fuel Price
            div do
              label for: "fuel-price", class: "block text-sm font-medium text-gray-700 mb-1" do
                "Fuel Price (Currency per liter)"
              end
              input type: "number",
                    id: "fuel-price",
                    step: "0.01",
                    min: "0",
                    placeholder: "e.g., 1.85",
                    class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                    data: {
                      fuel_economy_target: "fuelPrice",
                      action: "input->fuel-economy#calculate"
                    }
              p class: "mt-1 text-xs text-gray-500" do
                "Enter the current fuel price per liter"
              end
            end

            # Fuel Consumption
            div do
              label for: "fuel-consumption", class: "block text-sm font-medium text-gray-700 mb-1" do
                "Fuel Consumption (liters per 100 km)"
              end
              input type: "number",
                    id: "fuel-consumption",
                    step: "0.1",
                    min: "0",
                    placeholder: "e.g., 7.5",
                    class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                    data: {
                      fuel_economy_target: "fuelConsumption",
                      action: "input->fuel-economy#calculate"
                    }
              p class: "mt-1 text-xs text-gray-500" do
                "Your vehicle's average fuel consumption"
              end
            end

            # Number of Passengers
            div do
              label for: "num-passengers", class: "block text-sm font-medium text-gray-700 mb-1" do
                "Number of Passengers"
              end
              input type: "number",
                    id: "num-passengers",
                    min: "1",
                    value: "1",
                    placeholder: "e.g., 4",
                    class: "block w-full rounded-md border-gray-300 shadow-sm focus:border-blue-500 focus:ring-blue-500 sm:text-sm",
                    data: {
                      fuel_economy_target: "numPassengers",
                      action: "input->fuel-economy#calculate"
                    }
              p class: "mt-1 text-xs text-gray-500" do
                "Total number of people in the vehicle"
              end
            end
          end

          # Results Section
          div class: "border-t pt-6 hidden",
              data: { fuel_economy_target: "results" } do
            h3 class: "text-base font-semibold text-gray-900 mb-4" do
              "Calculated Costs"
            end

            div class: "grid grid-cols-1 md:grid-cols-2 gap-4" do
              # Left column - Per route costs
              div class: "space-y-3" do
                div class: "bg-gray-50 p-4 rounded-lg" do
                  div class: "text-sm font-medium text-gray-500 mb-1" do
                    "Total Fuel Needed"
                  end
                  div class: "text-2xl font-bold text-gray-900",
                      data: { fuel_economy_target: "totalFuel" } do
                    "-"
                  end
                  div class: "text-xs text-gray-500" do
                    "liters for this route"
                  end
                end

                div class: "bg-blue-50 p-4 rounded-lg" do
                  div class: "text-sm font-medium text-blue-700 mb-1" do
                    "Total Fuel Cost"
                  end
                  div class: "text-2xl font-bold text-blue-900",
                      data: { fuel_economy_target: "totalCost" } do
                    "-"
                  end
                  div class: "text-xs text-blue-600" do
                    "Currency for this route"
                  end
                end
              end

              # Right column - Per person/km costs
              div class: "space-y-3" do
                div class: "bg-green-50 p-4 rounded-lg" do
                  div class: "text-sm font-medium text-green-700 mb-1" do
                    "Cost per Passenger"
                  end
                  div class: "text-2xl font-bold text-green-900",
                      data: { fuel_economy_target: "costPerPassenger" } do
                    "-"
                  end
                  div class: "text-xs text-green-600" do
                    "Currency per person"
                  end
                end

                div class: "bg-yellow-50 p-4 rounded-lg" do
                  div class: "text-sm font-medium text-yellow-700 mb-1" do
                    "Cost per Kilometer"
                  end
                  div class: "text-2xl font-bold text-yellow-900",
                      data: { fuel_economy_target: "costPerKm" } do
                    "-"
                  end
                  div class: "text-xs text-yellow-600" do
                    "Currency per km"
                  end
                end
              end
            end

            # Round trip section
            div class: "mt-6 p-4 bg-purple-50 rounded-lg" do
              div class: "flex items-center mb-2" do
                input type: "checkbox",
                      id: "round-trip",
                      class: "h-4 w-4 text-purple-600 focus:ring-purple-500 border-gray-300 rounded",
                      data: {
                        fuel_economy_target: "roundTrip",
                        action: "change->fuel-economy#calculate"
                      }
                label for: "round-trip", class: "ml-2 text-sm font-medium text-gray-700" do
                  "Calculate for round trip"
                end
              end

              div class: "hidden",
                  data: { fuel_economy_target: "roundTripResults" } do
                div class: "text-sm font-medium text-purple-700 mb-1" do
                  "Round Trip Total Cost"
                end
                div class: "text-2xl font-bold text-purple-900",
                    data: { fuel_economy_target: "roundTripCost" } do
                  "-"
                end
                div class: "text-xs text-purple-600" do
                  span { "Currency for round trip (" }
                  span data: { fuel_economy_target: "roundTripCostPerPassenger" } do
                    "-"
                  end
                  span { " per passenger)" }
                end
              end
            end
          end

          # No data message (shown when distance is not available)
          if !@route.distance_in_km
            div class: "mt-6 p-4 bg-yellow-50 border border-yellow-200 rounded-lg" do
              div class: "flex" do
                svg_icon path_d: "M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z",
                         class: "h-5 w-5 text-yellow-400",
                         stroke_linecap: "round",
                         stroke_linejoin: "round",
                         stroke_width: "2"
                div class: "ml-3" do
                  h3 class: "text-sm font-medium text-yellow-800" do
                    "Distance not available"
                  end
                  p class: "mt-1 text-sm text-yellow-700" do
                    "The distance for this route could not be calculated. You can still use the calculator by entering a manual distance estimate."
                  end
                end
              end
            end
          end
        end

        # Information Card
        div class: "mt-6 bg-blue-50 rounded-lg p-6" do
          h3 class: "text-base font-semibold text-blue-900 mb-2" do
            "About this Calculator"
          end
          ul class: "space-y-1 text-sm text-blue-800 list-disc list-inside" do
            li { "All calculations are performed in your browser - no data is stored" }
            li { "Fuel prices and consumption rates can vary significantly" }
            li { "This is an estimate for budgeting purposes only" }
            li { "Actual costs may differ based on driving conditions and route taken" }
          end
        end
      end
    end
  end

  private

  def vehicle_icon_path(vehicle_type)
    case vehicle_type
    when 'car' then "M16 4h.01M4 20h16l-4-6H4l-4 6zm4-10h8"
    when 'motorcycle' then "M5 21h14v-2a2 2 0 00-2-2H7a2 2 0 00-2 2v2zM12 7V3m0 0l-3 3m3-3l3 3"
    when 'bicycle' then "M12 14l9-5-9-5-9 5 9 5zm0 7l-5.6-3.2a1 1 0 01-.4-.8V10l6 3.4 6-3.4v6.5a1 1 0 01-.4.8L12 21z"
    when 'skateboard' then "M16 6l-4 14-4-14"
    when 'scooter' then "M5 21h14v-2a2 2 0 00-2-2H7a2 2 0 00-2 2v2z"
    else "M3 21h18v-2H3v2zm3-18h12v12H6V3z"
    end
  end
end
