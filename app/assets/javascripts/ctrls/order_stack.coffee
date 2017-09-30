window.OrderStack =

  events: ->
    OrderStack.dataTableEntries()

  dataTableEntries: ->
    $(document).on 'change', 'select#per_page', ->
      $.ajax
        url: '/containers/per_order_stack'
        type: 'GET'
        data:
          per: $(this).val()


OrderStack.events()