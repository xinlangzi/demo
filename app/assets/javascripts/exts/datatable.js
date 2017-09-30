$.fn.dataTableExt.afnSortData['cell'] = function(settings, col)
{
  return this.api().column(col, {order:'index'}).nodes().map(function(td, i){
    return $(td).attr('rel');
  });
}

$.fn.dataTableExt.afnSortData['dom-text'] = function(settings, col)
{
  return this.api().column(col, {order:'index'}).nodes().map(function(td, i){
    return $('input', td).val();
  });
}
$.fn.dataTableExt.afnSortData['dom-textarea'] = function(settings, col)
{
  return this.api().column(col, {order:'index'}).nodes().map(function(td, i){
    return $('textarea', td).val();
  });
}
/* Create an array with the values of all the select options in a column */
$.fn.dataTable.ext.order['dom-select'] = function  ( settings, col )
{
  return this.api().column(col, {order:'index'}).nodes().map(function(td, i){
    return $('select', td).val();
  });
}

$.fn.dataTableExt.oSort['currency-asc']  = function(x, y) {
  x = x.replace( /\,|\$/g, "" )
  y = y.replace( /\,|\$/g, "" )
  x = parseFloat(x);
  y = parseFloat(y);
  return ((x < y) ? -1 : ((x > y) ? 1 : 0))
};

$.fn.dataTableExt.oSort['currency-desc'] = function(x,y) {
  x = x.replace( /\,|\$/g, "" )
  y = y.replace( /\,|\$/g, "" )
  x = parseFloat(x);
  y = parseFloat(y);
  return ((x < y) ? 1 : ((x > y) ? -1 : 0))
};

$.fn.dataTableExt.oSort['numric-asc']  = function(x,y) {
  x = parseInt(x);
  y = parseInt(y);
  return ((x < y) ? -1 : ((x > y) ?  1 : 0));
};

$.fn.dataTableExt.oSort['numric-desc'] = function(x,y) {
  x = parseInt(x);
  y = parseInt(y);
  return ((x < y) ?  1 : ((x > y) ? -1 : 0));
};
