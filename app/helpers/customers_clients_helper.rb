module CustomersClientsHelper
  def detailed_column_list
    list = super
    list['Customer'] = lambda{|c| link_to c.customer.name, c.customer}
    list
  end

  def datatable_sort_types
    options =<<EOF
{
  "bStateSave": true,
  "bPaginate": false,
  "aaSorting": [[ 0, "desc" ]],
  "aoColumns": [
    null,
    null,
    null,
    null,
    #{'null,' if current_user.is_admin?}
    {"bSortable": false},
    {"bSortable": false},
    {"bSortable": false}
  ]
}
EOF
  end
end
