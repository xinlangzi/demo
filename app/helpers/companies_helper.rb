module CompaniesHelper

  def column_list
    {
     'Name' => ->(c){ link_to(c.name, c).html_safe},
     'State' => ->(c){ h c.state },
     'Containers' => ->(c){ h c.containers.count("DISTINCT containers.id")}
    }
  end

  def actions_list
    {
      'View'      => ->(c){ link_to('', c, class: 'fa fa-info-circle') },
      'Edit'      => ->(c){ link_to('', [:edit, c], class: 'fa fa-edit') if !c.deleted?},
      'Delete'    => ->(c){ link_to('', c, data: { confirm: 'Are you sure you want to delete it?' }, method: :delete, class: 'fa fa-trash') if !c.deleted?},
      'Undelete'  => ->(c){ link_to('', polymorphic_path(c, :action => :undelete), class: 'fa fa-undo', data: {confirm: 'Are you sure to restore it?'}, method: :put) if c.deleted? },
      'Deleted At'=> ->(c){ c.deleted_at.us_datetime if c.deleted? }
    }
  end

  # detailed_column_list is used to show one company, it's more comprehensive
  def detailed_column_list
    {
      'Name'              => ->(c){ h c.name },
      'Contact Person'    => ->(c){ h c.contact_person },
      'Main Email'        => ->(c){ mail_to c.email },
      'Phone'             => ->(c){ h c.phone },
      'Mobile'            => ->(c){ h c.phone_mobile },
      'Fax'               => ->(c){ h c.fax },
      'Address'           => ->(c){ [c.address_street, c.city_state_zip].compact.join('<br>').html_safe },
      'Extra Contact Info.' => ->(c){ simple_format(c.extra_contact_info) },
      'Containers'        => ->(c){ h c.containers.count },
      'Comments'          => ->(c){ h c.comments }
    }
  end

end
