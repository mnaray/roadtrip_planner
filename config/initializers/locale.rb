# frozen_string_literal: true

# Keep English as default locale but configure Swiss timezone
Rails.application.config.i18n.default_locale = :en
Rails.application.config.i18n.available_locales = [ :en ]

# Set timezone to Swiss timezone
Rails.application.config.time_zone = "Bern"
