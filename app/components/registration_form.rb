class RegistrationForm < ApplicationComponent
  def initialize(user)
    @user = user
  end

  def view_template
    validation_errors = @user.errors.any? ? @user.errors.full_messages.join(", ") : nil

    div class: "min-h-screen flex items-center justify-center py-12 px-4 sm:px-6 lg:px-8",
        **validation_errors_data(validation_errors) do
      div class: "max-w-md w-full space-y-8" do
        div do
          h2 class: "mt-6 text-center text-3xl font-extrabold text-gray-900" do
            "Create your account"
          end
          p class: "mt-2 text-center text-sm text-gray-600" do
            "Already have an account? "
            link_to "Sign in", login_path, class: "font-medium text-blue-600 hover:text-blue-500"
          end
        end

        form_with model: @user, url: register_path, local: true, class: "mt-8 space-y-6" do |form|
          # Error messages will now be shown as popup notifications

          div class: "space-y-4" do
            div do
              form.label :username, class: "block text-sm font-medium text-gray-700 mb-1" do
                "Username"
              end
              form.text_field :username,
                             required: true,
                             autofocus: true,
                             class: field_classes(:username, "appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"),
                             placeholder: "Enter your username (min. 3 characters)"
            end

            div do
              form.label :password, class: "block text-sm font-medium text-gray-700 mb-1" do
                "Password"
              end
              form.password_field :password,
                                 required: true,
                                 class: field_classes(:password, "appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"),
                                 placeholder: "Enter your password (min. 8 chars with letters & numbers)"
            end

            div do
              form.label :password_confirmation, class: "block text-sm font-medium text-gray-700 mb-1" do
                "Confirm Password"
              end
              form.password_field :password_confirmation,
                                 required: true,
                                 class: field_classes(:password_confirmation, "appearance-none rounded-md relative block w-full px-3 py-2 border border-gray-300 placeholder-gray-500 text-gray-900 focus:outline-none focus:ring-blue-500 focus:border-blue-500 focus:z-10 sm:text-sm"),
                                 placeholder: "Confirm your password"
            end
          end

          div do
            form.submit "Create Account",
                       class: "group relative w-full flex justify-center py-2 px-4 border border-transparent text-sm font-medium rounded-md text-white bg-blue-600 hover:bg-blue-700 focus:outline-none focus:ring-2 focus:ring-offset-2 focus:ring-blue-500 transition-colors"
          end
        end
      end
    end
  end

  private

  def pluralize(count, singular, plural = nil)
    word = if count == 1
             singular
    else
             plural || "#{singular}s"
    end
    "#{count} #{word}"
  end

  def validation_errors_data(errors)
    errors ? { "data-validation-errors" => errors } : {}
  end

  def field_classes(field, base_classes)
    if @user.errors[field].any?
      "#{base_classes} field-error"
    else
      base_classes
    end
  end
end
