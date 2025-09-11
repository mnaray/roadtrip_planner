module ApplicationHelper
  # Format dates in Swiss format (DD/MM/YYYY or DD.MM.YYYY with time)
  def swiss_date_format(datetime, format_type = :long)
    return unless datetime

    case format_type
    when :short
      datetime.strftime("%d.%m.%Y")
    when :long
      datetime.strftime("%d.%m.%Y at %H:%M")
    when :with_day
      datetime.strftime("%A, %d. %B %Y at %H:%M")
    else
      datetime.strftime("%d.%m.%Y %H:%M")
    end
  end
end
