module DriversHelper
    # If the date is in the past, it prints an expired! next to it
  def check_date_status(date)
    case true
    when date.blank?
      :missing
    when date > Date.today
      date < Date.today + 30.days ? :expiring : :normal
    else
      :expired
    end
  end

  def display_date_with_status(date, date_show: nil, applicable: true)
    date_show||= date
    status = :not_applicable unless applicable
    status||= check_date_status(date)
    case status
    when :not_applicable
      content_tag(:span, 'not applicable', class: 'green')
    when :missing
      date_show.nil? ? content_tag(:span, 'missing', class: 'missing') : h(date_show)
    when :expiring
      content_tag(:span, "#{date_show} expiring", class: 'expiring')
    when :normal
      content_tag(:span, date_show, class: 'normal')
    else
      content_tag(:span, "#{date_show} expired!", class: 'expired')
    end
  end

  def expiring_column_list
    {
                      hire_date: ->(c){ c.hire_date },
      driver_license_expiration: ->(c){ display_date_with_status(c.dl_expiration_date) },
        medical_card_expiration: ->(c){ display_date_with_status(c.medical_card_expiration_date) }
    }
  end

  def truck_expiring_column_list
    {
                                   truck_no: ->(t){ link_to("truck #{t.number}", edit_truck_path(t), target: '_blank') },
               annual_inspection_expiration: ->(t){ display_date_with_status(t.tai_expiration) },
                   license_plate_expiration: ->(t){ display_date_with_status(t.license_plate_expiration) },
                            ifta_expiration: ->(t){ display_date_with_status(t.ifta_expiration, applicable: t.ifta_applicable) },
               bobtail_insurance_expiration: ->(t){ display_date_with_status(t.bobtail_insurance_expiration) },
      last_quarterly_maintenance_expiration: ->(t){ display_date_with_status(t.last_quarterly_maintenance_report, date_show: t[:last_quarterly_maintenance_report]) }
    }
  end

  def x_week_pay
    [['1 week pay', 1], ['2 week pay', 2]]
  end
end
