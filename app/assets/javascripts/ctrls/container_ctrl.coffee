window.ContainerCtrl =

  refreshOnCalendar: (id)->
    if $('#container-on-calendar').exists() && $('.container' + id).exists()
      $.ajax
        url: '/containers/' + id + '/reload'
        type: 'GET'
        data:
          partial: 'calendar/row'

  refreshOnOrderStack: (id)->
    if $('table.order-stack').exists() && $('.container' + id).exists()
      $.ajax
        url: '/containers/' + id + '/reload'
        type: 'GET'
        data:
          partial: 'order_stack/row'