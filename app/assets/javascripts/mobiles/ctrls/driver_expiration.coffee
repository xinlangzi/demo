window.DriverExpiration =

  reload: ->
    $.ajax
      url: '/mobiles/drivers/expirations'
      type: 'GET'
      dataType: 'html'
      success: (html)->
        $('#driver-expirations .accordion-item-content').replaceWith($(html).find('.accordion-item-content')) # keep accordion-item-expanded
