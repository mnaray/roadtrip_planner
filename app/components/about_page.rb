require "commonmarker"

class AboutPage < Phlex::HTML
  def initialize(current_user: nil)
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "About - Roadtrip Planner", current_user: @current_user) do
      div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12" do
        article class: "prose prose-lg prose-blue max-w-none" do
          raw markdown_content.html_safe
        end
      end
    end
  end

  private

  def markdown_content
    markdown_file_path = Rails.root.join("app", "content", "about.md")
    markdown_text = File.read(markdown_file_path)

    # Configure Commonmarker with GitHub-flavored markdown features
    Commonmarker.to_html(
      markdown_text,
      options: {
        parse: {
          unsafe: false,
          smart: true
        },
        render: {
          unsafe: false,
          github_pre_lang: true
        }
      }
    )
  end
end
