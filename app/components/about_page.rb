require "commonmarker"

class AboutPage < Phlex::HTML
  def initialize(current_user: nil)
    @current_user = current_user
  end

  def view_template
    render ApplicationLayout.new(title: "About - Roadtrip Planner", current_user: @current_user) do
      div class: "max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-12" do
        div class: "bg-white p-8 rounded-lg shadow-sm" do
          article class: "prose prose-lg prose-gray mx-auto prose-headings:font-bold prose-h1:text-3xl prose-h2:text-xl prose-h2:font-semibold prose-h3:text-lg prose-h3:font-semibold prose-h4:text-base prose-h4:font-medium" do
            raw markdown_content.html_safe
          end
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
