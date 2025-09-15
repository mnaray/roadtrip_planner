# frozen_string_literal: true

# Component for rendering a visibility toggle (private/public) with descriptive labels
class Shared::VisibilityToggleComponent < ApplicationComponent
  def initialize(form:, field: :visibility, label: "Visibility", help_text: nil)
    @form = form
    @field = field
    @label = label
    @help_text = help_text
  end

  def view_template
    div class: "space-y-4" do
      div do
        @form.label @field, class: "block text-sm font-medium text-gray-700 mb-3" do
          @label
        end

        div class: "space-y-2" do
          # Private option (default)
          div class: "flex items-start" do
            div class: "flex items-center h-5" do
              @form.radio_button @field, "private",
                                 id: "#{@field}_private",
                                 class: "focus:ring-blue-500 h-4 w-4 text-blue-600 border-gray-300"
            end
            div class: "ml-3 text-sm" do
              @form.label "#{@field}_private", class: "font-medium text-gray-700 cursor-pointer" do
                "Private"
              end
              p class: "text-gray-500" do
                "Only you can see this packing list"
              end
            end
          end

          # Public option
          div class: "flex items-start" do
            div class: "flex items-center h-5" do
              @form.radio_button @field, "public",
                                 id: "#{@field}_public",
                                 class: "focus:ring-blue-500 h-4 w-4 text-blue-600 border-gray-300"
            end
            div class: "ml-3 text-sm" do
              @form.label "#{@field}_public", class: "font-medium text-gray-700 cursor-pointer" do
                "Public"
              end
              p class: "text-gray-500" do
                "All trip participants can see this packing list"
              end
            end
          end
        end

        # Help text
        if @help_text
          p class: "mt-2 text-sm text-gray-600" do
            @help_text
          end
        end

        # Error display
        if @form.object&.errors&.[](@field)&.any?
          div class: "mt-2 text-sm text-red-600" do
            @form.object.errors[@field].first
          end
        end
      end
    end
  end
end
