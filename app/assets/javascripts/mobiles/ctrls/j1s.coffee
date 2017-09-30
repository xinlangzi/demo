window.J1s =

  reload: ->
    $.ajax
      url: '/mobiles/home/j1s'
      type: 'GET'
      dataType: 'html'
      success: (html)->
        $('#j1s .accordion-item-content').replaceWith($(html).find('.accordion-item-content')) # keep accordion-item-expanded
        SwiperSlide.init()
