class ApplicationLayout < Phlex::HTML
  include Phlex::Rails::Helpers::CSRFMetaTags
  include Phlex::Rails::Helpers::CSPMetaTag
  include Phlex::Rails::Helpers::StylesheetLinkTag
  include Phlex::Rails::Helpers::JavascriptImportmapTags

  def initialize(title: "App", current_user: nil)
    @title = title
    @current_user = current_user
  end

  def view_template
    doctype

    html class: "h-full" do
      head do
        title { @title }
        meta name: "viewport", content: "width=device-width,initial-scale=1"
        meta name: "apple-mobile-web-app-capable", content: "yes"
        meta name: "mobile-web-app-capable", content: "yes"
        csrf_meta_tags
        csp_meta_tag

        link rel: "icon", href: "/icon.png", type: "image/png"
        link rel: "icon", href: "/icon.svg", type: "image/svg+xml"
        link rel: "apple-touch-icon", href: "/icon.png"

        # Google Fonts for better typography
        link rel: "preconnect", href: "https://fonts.googleapis.com"
        link rel: "preconnect", href: "https://fonts.gstatic.com", crossorigin: true
        link rel: "stylesheet", href: "https://fonts.googleapis.com/css2?family=Inter:wght@300;400;500;600;700&display=swap"

        stylesheet_link_tag "application", "data-turbo-track": "reload"
        javascript_importmap_tags
      end

      body class: "h-full bg-gradient-to-br from-slate-50 to-blue-50 text-gray-800" do
        render Navigation.new(current_user: @current_user)

        # Flash messages
        flash_messages

        main class: "min-h-screen" do
          yield if block_given?
        end
      end
    end
  end

  private

  def flash_messages
    flash_types = { notice: "bg-green-50 text-green-800 border-green-200",
                   alert: "bg-red-50 text-red-800 border-red-200" }

    flash_types.each do |type, classes|
      if helpers.flash[type].present?
        div class: "max-w-7xl mx-auto px-4 sm:px-6 lg:px-8 mt-4" do
          div class: "rounded-md p-4 border #{classes}" do
            p class: "text-sm font-medium" do
              helpers.flash[type]
            end
          end
        end
      end
    end
  end
end
