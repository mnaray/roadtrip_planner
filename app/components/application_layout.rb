class ApplicationLayout < Phlex::HTML
  include Phlex::Rails::Helpers::CSRFMetaTags
  include Phlex::Rails::Helpers::CSPMetaTag
  include Phlex::Rails::Helpers::StylesheetLinkTag
  include Phlex::Rails::Helpers::JavascriptImportmapTags

  def initialize(title: "App")
    @title = title
  end

  def view_template
    doctype

    html do
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

        stylesheet_link_tag "application", "data-turbo-track": "reload"
        javascript_importmap_tags
      end

      body do
        main { yield }
      end
    end
  end
end