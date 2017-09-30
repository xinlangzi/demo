module Accounting
  module TpCompaniesHelper
    def column_list
      list = {
        'Display name' => ->(c){ link_to(c.name, c).html_safe },
        'Name (Print on Check As)' => ->(c){ h c.print_name },
        'FEIN' => ->(c){ h c.fein },
        'Address' => ->(c){ c.address.html_safe }
      }

      list['For Container'] = ->(c){
        fields_for(c){|f|
          f.check_box(:for_container, class: "auto-save center", id: "for_container_#{c.id}", ref: "#{c.class.to_s}:#{c.id}:for_container")
        }
      } if current_user.is_superadmin?

      list['Only For Acct.'] = ->(c){
        fields_for(c){|f|
          f.check_box(:acct_only, class: "auto-save center", id: "acct_only_#{c.id}", ref: "#{c.class.to_s}:#{c.id}:acct_only")
        }
      } if current_user.is_superadmin?

      list
    end

    def actions_list
      {
        'View'      => ->(c){ link_to('', c, class: 'fa fa-info-circle') },
        'Edit'      => ->(c){ link_to('', [:edit, c], class: 'fa fa-edit') },
        'Delete'    => ->(c){ link_to('', polymorphic_path(c, action: :delete), remote: true, class: 'fa fa-trash', confirm: "Are you sure you want to delete #{h c.name}?", method: :get) if c.inactived?&!c.deleted?},
        'Undelete'  => ->(c){ link_to('', polymorphic_path(c, action: :undelete), class: 'fa fa-undo', :confirm => "Are you sure you want to undelete #{h c.name}?", :method => :get) if c.deleted? },
        'Inactivate'=> ->(c){ link_to('Inactivate', polymorphic_path(c, action: :inactivate), data: { confirm: "Are you sure you want to inactivate #{h c.name}?" }, :method => :get) unless c.inactived? },
        'Activate'=> ->(c){ link_to('Activate', polymorphic_path(c, action: :activate), data: { confirm: "Are you sure you want to activate #{h c.name}?" }, :method => :get) if c.inactived?&!c.deleted?}

      }
    end

    def detailed_column_list
      list = {
        'Display name' => ->(c){ h c.name },
        'Name (Print on Check As)' => ->(c){ h c.print_name },
        'FEIN' => ->(c){ h c.fein },
        'Address' => ->(c){ "#{h c.address_street}<br />#{h c.address_street_2}<br />#{h c.address_city}, #{h c.state} #{h c.zip_code}".html_safe },
        'Email' => ->(c){ c.email },
        'Phone' => ->(c){ [c.phone, (c.phone_extension.blank? ? '' : "ext: #{c.phone_extension}")].join(' ') },
        'Mobile' => ->(c){ c.phone_mobile },
        'Fax' => ->(c){ c.fax },
        'Website' => ->(c){ c.web }
      }
      list['For Container'] = ->(c){ checkmark(c.for_container) } if current_user.is_superadmin?
      list['Only For Acct.'] = ->(c){ checkmark(c.acct_only) } if current_user.is_superadmin?
      list
    end
  end
end
