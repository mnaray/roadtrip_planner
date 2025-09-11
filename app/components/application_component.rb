class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::Routes
  include ApplicationHelper

  # Helper method to create complete SVG icons without using path method
  def svg_icon(path_d:, **svg_attributes)
    # Set default SVG attributes
    defaults = {
      fill: "none",
      stroke: "currentColor",
      viewBox: "0 0 24 24"
    }
    attrs = defaults.merge(svg_attributes)

    # Generate complete SVG HTML as a string
    svg_attrs_str = attrs.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
    svg_html = "<svg #{svg_attrs_str}><path d=\"#{path_d}\"></path></svg>"

    # Use raw to output unescaped HTML (mark as html_safe first)
    raw svg_html.html_safe
  end
end
