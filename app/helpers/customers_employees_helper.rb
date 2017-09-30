module CustomersEmployeesHelper
  include UsersHelper
  def column_list
    list = super
    list["Customer"] = lambda{|c| link_to(c.customer.name, c.customer) if c.customer}
    list
  end


  def detailed_column_list
    {
     'Name' => lambda{|c| h c.name},
     'Customer' => lambda{|c| link_to(c.customer.name, c.customer) if c.customer},
     'Email Address' => lambda{|c| mail_to c.email },
     'Last Login' => lambda{|c| c.last_login.try(:to_formatted_s, :db)},
     'Failed Logins' => lambda{|c| h c.failed_login_attempts},
     'Logins' => lambda{|c| h c.logins},
     'Containers' => lambda{|c| h c.containers.count},
     'Comments' => lambda{|c| h c.comments}
    }
  end
end
