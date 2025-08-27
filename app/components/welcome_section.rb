class WelcomeSection < Phlex::HTML
  def view_template
    div class: "min-h-screen flex items-center justify-center px-4 sm:px-6 lg:px-8" do
      div class: "max-w-4xl mx-auto text-center" do
        # Hero Section
        div class: "animate-fade-in" do
          # Main heading with gradient text
          h1 class: "text-5xl md:text-7xl font-bold mb-6 bg-gradient-to-r from-primary-600 via-accent-600 to-primary-500 bg-clip-text text-transparent animate-bounce-in" do
            "Roadtrip Planner"
          end
          
          # Subtitle
          p class: "text-xl md:text-2xl text-gray-600 mb-8 font-light animate-slide-up animate-delay-200" do
            "Your adventure starts here"
          end
        end
        
        # Feature cards
        div class: "grid md:grid-cols-3 gap-6 mb-12 animate-fade-in animate-delay-400" do
          feature_card(
            icon: "🚗", 
            title: "Plan Routes", 
            description: "Create amazing roadtrip routes with ease"
          )
          feature_card(
            icon: "📍", 
            title: "Discover Places", 
            description: "Find hidden gems along your journey"
          )
          feature_card(
            icon: "🗺️", 
            title: "Share Adventures", 
            description: "Share your roadtrip stories with friends"
          )
        end
        
        # Technology stack info
        div class: "glass-effect rounded-2xl p-8 backdrop-blur-lg border border-white/20 shadow-xl animate-slide-up animate-delay-600" do
          h3 class: "text-2xl font-semibold mb-6 text-gray-800" do
            "Powered by Modern Technology"
          end
          
          div class: "grid grid-cols-2 md:grid-cols-4 gap-4 text-sm" do
            tech_badge("Rails #{Rails.version}", "bg-red-100 text-red-700")
            tech_badge("Ruby #{RUBY_VERSION}", "bg-red-100 text-red-700")
            tech_badge("Phlex Components", "bg-purple-100 text-purple-700")
            tech_badge("Tailwind CSS v4", "bg-blue-100 text-blue-700")
          end
        end
        
        # Call to action
        div class: "mt-12 animate-bounce-in animate-delay-800" do
          button class: "group relative inline-flex items-center justify-center px-8 py-4 text-lg font-medium text-white transition-all duration-300 bg-gradient-to-r from-primary-600 to-accent-600 rounded-full hover:from-primary-700 hover:to-accent-700 hover:shadow-2xl hover:scale-105 focus:outline-none focus:ring-4 focus:ring-primary-300" do
            span class: "relative z-10" do
              "Start Your Journey"
            end
            
            # Animated background
            div class: "absolute inset-0 rounded-full bg-gradient-to-r from-primary-400 to-accent-400 opacity-0 group-hover:opacity-100 transition-opacity duration-300 animate-pulse"
          end
        end
      end
    end
  end
  
  private
  
  def feature_card(icon:, title:, description:)
    div class: "group p-6 bg-white/70 backdrop-blur-sm rounded-2xl shadow-lg border border-white/20 hover:shadow-2xl hover:bg-white/80 transition-all duration-300 hover:scale-105" do
      div class: "text-4xl mb-4 group-hover:scale-110 transition-transform duration-300" do
        icon
      end
      h3 class: "text-xl font-semibold mb-2 text-gray-800" do
        title
      end
      p class: "text-gray-600 leading-relaxed" do
        description
      end
    end
  end
  
  def tech_badge(text, color_classes)
    span class: "inline-flex items-center px-3 py-2 rounded-full text-xs font-medium #{color_classes} border border-current/20" do
      text
    end
  end
end