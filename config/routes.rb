Rails.application.routes.draw do
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Authentication routes
  get "register", to: "registrations#new", as: :register
  post "register", to: "registrations#create"
  get "login", to: "sessions#new", as: :login
  post "login", to: "sessions#create"
  delete "logout", to: "sessions#destroy", as: :logout

  # Vehicle garage routes
  get "garage", to: "vehicles#index", as: :garage
  resources :vehicles, path: "garage/vehicles" do
    member do
      patch :set_default
    end
  end

  # Road trip planning routes
  resources :road_trips do
    resources :routes, except: [ :index ], shallow: true
    resources :packing_lists do
      resources :packing_list_items do
        member do
          patch :toggle_packed
        end
      end
    end
    resources :participants, only: [ :index, :create, :destroy ]
    member do
      delete :leave
    end
  end

  # Special route flow for confirmation and approval
  get "confirm_route", to: "routes#confirm_route"
  post "approve_route", to: "routes#approve_route"

  # Waypoint flow
  get "set_waypoints", to: "waypoints#set_waypoints"
  post "set_waypoints", to: "waypoints#create"

  # Waypoint management
  resources :waypoints, only: [ :destroy ] do
    member do
      patch :recalculate_route_metrics
    end
  end
  get "routes/:id/map", to: "routes#map", as: :route_map
  get "routes/:id/export_gpx", to: "routes#export_gpx", as: :route_export_gpx
  get "routes/:id/edit_waypoints", to: "routes#edit_waypoints", as: :edit_route_waypoints
  patch "routes/:id/update_waypoints", to: "routes#update_waypoints", as: :update_route_waypoints
  get "routes/:route_id/fuel_economy", to: "fuel_economies#show", as: :route_fuel_economy

  # API endpoints for route data (avoids CORS issues)
  get "api/route_data", to: "routes#route_data", as: :api_route_data
  post "api/route_data_with_waypoints", to: "routes#route_data_with_waypoints", as: :api_route_data_with_waypoints

  # Static pages
  get "about", to: "pages#about", as: :about

  # Defines the root path route ("/")
  root "pages#home"
end
