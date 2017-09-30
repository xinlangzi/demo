module MobilesHelper
  # include TruckersHelper

  def logo_tag
    image_tag(cowner.logo.url, alt: cowner.name, height: 72)
  end

  def f7_label_text(label, text)
    content_tag :li, class: 'relative' do
      content_tag :div, class: 'item-content small' do
        content_tag :div, class: 'item-inner' do
          if block_given?
            content_tag(:div, label, class: 'item-title label') + content_tag(:div, class: 'item-value'){ yield }
          else
            content_tag(:div, label, class: 'item-title label') + content_tag(:div, text, class: 'item-value')
          end
        end
      end
    end
  end

  def google_map_url(address)
    uri = URI.parse('http://maps.google.com')
    uri.query = URI.encode_www_form(q: address)
    uri.to_s
  end

  def attach_url_for_expiration_date(object, column_name)
    new_mobiles_drivers_expiration_path({
      image: {
        imagable_type: object.class.table_name.classify,
        imagable_id: object.id,
        column_name: column_name
      }
    })
  end

  def profile_column_list
    defaults = {
     'Name' => ->(c){ h c.name},
     'Contact Person' => ->(c){ h c.contact_person},
     'Main Email' => ->(c){ mail_to c.email },
     'Phone' => ->(c){ h c.phone},
     'Fax' => ->(c){ h c.fax},
     'Address' => ->(c){ "#{h c.address_street}<br />#{h c.address_city}, #{h c.state} #{h c.zip_code}".html_safe},
     'Extra Contact Info.' => ->(c){ simple_format(c.extra_contact_info) },
     'Containers' => ->(c){ h c.containers.count} ,
     'Comments' => ->(c){ h c.comments}
    }
    case current_user.class.to_s
    when /Trucker/
      defaults.delete("Name")
      defaults.insert(0, "Display Name", ->(c){ h c.name })
      defaults['Name']                 = ->(c){ h c.print_name }
      defaults['FEIN']                 = ->(c){ h c.fein}
      defaults['1099']                 = ->(c){ c.onfile1099 ? "✔" : "" }
      defaults["Date of Birth"]        = ->(c){ h c.date_of_birth.try(:to_formatted_s, :long) }
      defaults["Driver License No."]   = ->(c){ h c.dl_no}
      defaults["DL Issuing State"]     = ->(c){ h c.dl_state.try(:name) || 'N/A'}
      defaults["DL Expires"]           = ->(c){ display_date_with_status(c.dl_expiration_date) } if current_hub.driver_license_expiration #date_expired should output safe html
      defaults['CDL Haz Endorsement']  = ->(c){ c.dl_haz_endorsement ? checkmark(true) : 'N/A' }
      defaults['Social Security No.']  = ->(c){ h(c.ssn.blank? ? 'N/A' : '******')}
      defaults["Medical Card Expires"] = ->(c){ display_date_with_status(c.medical_card_expiration_date) } if current_hub.medical_card_expiration
      defaults["Hire Date"]            = ->(c){ c.hire_date}
      defaults["Termination Date"]     = ->(c){ c.termination_date} if current_user.is_admin?
      defaults["Week Pay"]             = ->(c){ "#{c.week_pay} week" if c.week_pay }
    when /SuperAdmin|Admin/
    else
      defaults = {}
    end
    defaults
  end

end
