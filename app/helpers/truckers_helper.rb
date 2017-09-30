module TruckersHelper
  def column_list
    list = super
    list.delete('Roles')
    list["Week Pay"]    = ->(c){ "#{c.week_pay} week" if c.week_pay }
    list["Drug Tests"]  = ->(c){ c.drug_tests.count}
    list["Trucks"]      = ->(c){ c.trucks.count}
    list['1099']        = ->(c){ checkmark(c.onfile1099) }
    list['Check Docs?'] = ->(c){ ### to-remove
      fields_for(c){|f|
        id = dom_id(c, "check-doc")
        f.check_box(:check_missing_doc, {
          class: "auto-save center",
          id: id,
          ref: "#{c.class.to_s}:#{c.id}:check_missing_doc",
          callback: "$('##{id}').attr('disabled', true)"
        })
      }
    }
    list['Hired Tasks'] = ->(c){
      icons = c.tasks_done?(:hired) ? 'fa fa-circle green' : 'fa fa-circle red'
      content_tag(:div, nil, class: icons, id: dom_id(c, 'hired')) +
      select_tag(
        :hired,
        options_for_select(SystemSetting.tasks_for_hired_driver, c.get_tasks(:hired)),
        { multiple: true, class: 'hired-tasks', id: dom_id(c, 'hired-task'), data: { id: c.id } }
      )
    }
    list['Terminated Tasks'] = ->(c){
      icons = c.tasks_done?(:terminated) ? 'fa fa-circle green' : 'fa fa-circle red'
      content_tag(:div, nil, class: icons, id: dom_id(c, 'terminated')) +
      select_tag(
        :terminated,
        options_for_select(SystemSetting.tasks_for_terminated_driver, c.get_tasks(:terminated)),
        { multiple: true, class: 'terminated-tasks', id: dom_id(c, 'terminated-task'), data: { id: c.id } }
      )
    }
    list
  end

  def detailed_column_list
    list = super
    list.delete("Name")
    list.insert(0, "Display Name", nil)
    list['Display Name']         = ->(c){
      html = h c.name
      html+= attachments_for(c, :avatar) if current_user.is_admin?
      html
    }
    list['Name']                 = ->(c){ h c.print_name}
    list['FEIN']                 = ->(c){ h c.fein}
    list['1099']                 = ->(c){ c.onfile1099 ? "✔" : ""}
    list['Billing Address']      = ->(c){ [c.billing_street, c.billing_city_state_zip].compact.join('<br>').html_safe }
    list["Date of Birth"]        = ->(c){ h c.date_of_birth.try(:to_formatted_s, :long)}
    list["Driver License No."]   = ->(c){ h c.dl_no}
    list["DL Issuing State"]     = ->(c){ h c.dl_state.try(:name) || 'N/A'}
    list["DL Expires"]           = ->(c){
      html = display_date_with_status(c.dl_expiration_date)
      html+= attachments_for(c, :driver_license_expiration) if current_user.is_admin?
      html
    } #date_expired should output safe html
    list['CDL Haz Endorsement']  = ->(c){ c.dl_haz_endorsement ? checkmark(true) : 'N/A'}
    list['Social Security No.']  = ->(c){ h c.ssn}
    list["Medical Card Expires"] = ->(c){
      html = display_date_with_status(c.medical_card_expiration_date)
      html+= attachments_for(c, :medical_card_expiration) if current_user.is_admin?
      html
    }
    list["Hire Date"]            = ->(c){ c.hire_date}
    list["Termination Date"]     = ->(c){ c.termination_date} if current_user.is_admin?
    list["Week Pay"]             = ->(c){ "#{c.week_pay} week" if c.week_pay }
    list["Final Docusign"]       = ->(c){ attachments_for(c, Trucker::DOCUSIGN_TAG) } if current_user.is_admin?
    list["PSP Docusign"]         = ->(c){ attachments_for(c, Trucker::PSP_TAG) } if current_user.is_admin?
    list["MVR Documents"]        = ->(c){ attachments_for(c, Trucker::MVR_TAG) } if current_user.is_admin?
    list["VOID Check"]           = ->(c){ attachments_for(c, Trucker::VOID_CHECK_TAG) } if current_user.is_admin?
    list["Other Documents"]      = ->(c){ attachments_for(c, Trucker::OTHER_TAG) } if current_user.is_admin?
    list
  end

end
