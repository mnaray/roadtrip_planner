class ApplicationComponent < Phlex::HTML
  include Phlex::Rails::Helpers::LinkTo
  include Phlex::Rails::Helpers::ButtonTo  
  include Phlex::Rails::Helpers::FormWith
  include Phlex::Rails::Helpers::TurboFrameTag
  include Phlex::Rails::Helpers::Routes
  
  # Helper method to render SVG as raw HTML to avoid path method conflict
  def svg_raw(content, **attributes)
    attrs = attributes.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
    # Use plain string to avoid method_missing conflicts
    plain "<svg #{attrs}>#{content}</svg>"
  end

  # Helper method to create SVG path element as string
  def svg_path(**attributes)
    attrs = attributes.map { |k, v| "#{k}=\"#{v}\"" }.join(" ")
    "<path #{attrs}></path>"
  end
end
