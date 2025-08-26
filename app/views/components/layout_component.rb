class LayoutComponent < ApplicationComponent
  def initialize(title: "Roadtrip Planner")
    @title = title
  end

  def view_template(&block)
    doctype
    
    html(lang: "en") do
      head do
        meta(charset: "utf-8")
        meta(name: "viewport", content: "width=device-width,initial-scale=1")
        title { @title }
        meta(name: "view-transition", content: "same-origin")
        
        csrf_meta_tags
        csp_meta_tag
        
        stylesheet_link_tag "application", "data-turbo-track": "reload"
        javascript_importmap_tags
      end
      
      body(class: "bg-gray-50 min-h-screen") do
        main(class: "container mx-auto px-4 py-8") do
          # Navigation
          nav(class: "mb-8") do
            div(class: "flex justify-between items-center") do
              link_to root_path, class: "text-2xl font-bold text-blue-600" do
                "🚗 Roadtrip Planner"
              end
              
              div(class: "space-x-4") do
                link_to "All Trips", trips_path, class: "text-blue-600 hover:text-blue-800"
                link_to "New Trip", new_trip_path, class: "bg-blue-600 text-white px-4 py-2 rounded hover:bg-blue-700"
              end
            end
          end
          
          # Flash messages
          if flash.any?
            div(class: "mb-4") do
              flash.each do |type, message|
                div(class: "p-4 rounded #{flash_class(type)}") do
                  message
                end
              end
            end
          end
          
          # Main content
          yield(block) if block
        end
      end
    end
  end

  private

  def flash_class(type)
    case type.to_sym
    when :notice
      "bg-green-100 border border-green-400 text-green-700"
    when :alert
      "bg-red-100 border border-red-400 text-red-700"
    else
      "bg-blue-100 border border-blue-400 text-blue-700"
    end
  end
  
  def stylesheet_link_tag(*args)
    # Simplified implementation for development
    link(rel: "stylesheet", href: asset_path("application.css"))
  end
  
  def javascript_importmap_tags
    # Simplified implementation for development
    script(src: asset_path("application.js"), defer: true)
  end
end