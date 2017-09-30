module CustomersHelper

  def column_list
    {
     'Name'       => lambda{|c| link_to(c.name, c).html_safe},
     'State'      => lambda{|c| h c.state },
     'Containers' => lambda{|c| h c.containers.count},
     'Consignees' => lambda{|c| link_to_if(!c.consignees.empty?, c.consignees.count, consignees_path(q: {customer_id_eq: c.id}))},
     'Shippers'   => lambda{|c| link_to_if(!c.shippers.empty?, c.shippers.count, shippers_path(q: {customer_id_eq: c.id}))},
     'Users'      => lambda{|c| link_to c.employees.active.count, customer_customers_employees_path(c) }
    }
  end

  def detailed_column_list
    list = super
    list.delete("Name")
    list.insert(0, 'Display Name', lambda{|c| h c.name })
    list['Name'] = lambda{|c| h c.print_name }
    list['FEIN'] = lambda{|c| h c.fein }
    list['Accounting Email'] = lambda{|c| mail_to c.accounting_email }
    list['Collection Email'] = lambda{|c| mail_to c.collection_email }
    list['Invoice J1s'] = lambda{|c| c.invoice_j1s.try(:titleize)}
    list['Users'] = lambda{|c|
          link_to( c.employees.active.count, customer_customers_employees_path(c) ) +
          ": " +
          c.employees.active.map{|e| link_to e.name, e}.join(', ').html_safe }
    list
  end
end
