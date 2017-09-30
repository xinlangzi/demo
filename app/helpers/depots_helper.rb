module DepotsHelper
  def detailed_column_list
    list = super
    list['Hours of Operation'] = lambda{|c| h c.ophours}
    list
  end
  def datatable_sort_types
    case current_user.class.to_s
    when /Admin|SuperAdmin/
<<EOF
{
  "bStateSave": true,
  "bPaginate": false,
  "aaSorting": [[ 0, "asc" ]],
  "aoColumns": [
    null,
    null,
    null,
    null,
    {"bSortable": false},
    {"bSortable": false},
    {"bSortable": false}
  ]
}
EOF
    when /Trucker/
<<EOF
{
  "bStateSave": true,
  "bPaginate": false,
  "aaSorting": [[ 0, "asc" ]],
  "aoColumns": [
    null,
    null,
    null,
    null,
    null
  ]
}
EOF
    end
  end
end
