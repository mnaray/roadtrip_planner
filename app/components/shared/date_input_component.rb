# frozen_string_literal: true

# Component for rendering date/time inputs with Swiss format
class Shared::DateInputComponent < ApplicationComponent
  def initialize(form:, field:, label:, required: true, classes: nil)
    @form = form
    @field = field
    @label = label
    @required = required
    @classes = classes || "w-full px-3 py-2 border border-gray-300 rounded-md shadow-sm focus:ring-blue-500 focus:border-blue-500 sm:text-sm"
  end

  def view_template
    div do
      @form.label @field,
                  class: "block text-sm font-medium text-gray-700 mb-2" do
        @label
      end

      @form.datetime_local_field @field,
                                 class: @classes,
                                 required: @required,
                                 data: { format: "dd/mm/yyyy HH:MM" },
                                 placeholder: "DD/MM/YYYY HH:MM"

      # Display format hint for users
      p class: "mt-1 text-xs text-gray-500" do
        "Format: DD/MM/YYYY HH:MM"
      end

      # Error display
      if @form.object&.errors&.[](@field)&.any?
        div class: "mt-1 text-sm text-red-600" do
          @form.object.errors[@field].first
        end
      end
    end
  end
end
