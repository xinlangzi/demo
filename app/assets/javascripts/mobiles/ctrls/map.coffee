window.Map =

  init: ->
    Map.trackDriver()

  trackDriver: ->
    $(document).on 'click', '.track-driver', ->
      F7H.app.popup('.map-popup')
      $('.map-popup').find('.content-block-title').html('Last Location of ' + $(this).data('name'))
      id = $(this).data('id')
      window.callback = ->
        new TrackTruck().locate(id);
      GoogleMap.loadScript(null, 'callback')

Map.init()
