window.Hub =

  events: ->
    Hub.switch()

  switch: ->
    $(document).on 'change', '.hub-switcher select', ->
      id = $(this).val() || 'All'
      $('.choose-order a').attr('disabled', true)
      $.ajax
        url: '/hubs/' + id + '/switch'
        type: "GET"

Hub.events()