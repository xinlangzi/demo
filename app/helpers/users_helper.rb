module UsersHelper
  def column_list
    {
      'Name' => ->(c){ link_to(c.name, c).html_safe },
      'Email' => ->(c){ c.email },
      'Containers' => ->(c){ c.containers.count },
      'Last Login' => ->(c){ c.last_login.try(:to_formatted_s, :db) },
      'Failed Logins' => ->(c){ c.failed_login_attempts },
      'Logins' => ->(c){ c.logins },
      'Roles' => ->(c){
        if c.is_superadmin?
          'Superadmin'
        else
          c.roles.map {|role|
            link_to_if current_user.is_admin?, role.name, edit_role_path(role)}.join(", ").html_safe
        end
       }
    }
  end
end
