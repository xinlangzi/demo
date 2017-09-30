window.Location =
  init: ->
    Location.trackLocationLayout()

  events: ->
    Location.showMap()

  trackLocationLayout: ->
    $('#track-location-layout').layout() if $('#track-location-layout').exists()

  showMap: ->
    $(document).on 'change', 'select.show-map', ->
      id = $(this).val() || 0
      $.ajax
        url: "/locations/" + id + "/map"
        type: 'GET'

Location.events()

$(document).on 'turbolinks:load', ->
  Location.init()