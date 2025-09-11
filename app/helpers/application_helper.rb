module ApplicationHelper
  # Format dates in Swiss format (DD/MM/YYYY or DD.MM.YYYY with time)
  def swiss_date_format(datetime, format_type = :long)
    return unless datetime

    case format_type
    when :short
      datetime.strftime("%d.%m.%Y")
    when :long
      datetime.strftime("%d.%m.%Y um %H:%M Uhr")
    when :with_day
      datetime.strftime("%A, %d. %B %Y um %H:%M Uhr")
    else
      datetime.strftime("%d.%m.%Y %H:%M")
    end
  end
end
