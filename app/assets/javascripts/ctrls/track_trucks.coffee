class @TrackTruck

  constructor: ()->

  locate: (id)->
    geocoder = new (google.maps.Geocoder)
    map = new (google.maps.Map)(document.getElementById('map'),
      zoom: 10
      center: new (google.maps.LatLng)(41.850033, -87.6500523)
      mapTypeId: google.maps.MapTypeId.ROADMAP)

    infowindow = new (google.maps.InfoWindow)

    loadMarker = ->
      $.getJSON '/drivers/' + id + '/locate.json', (data)->
        unless $.isEmptyObject(data)
          trucker = data['trucker']
          latitude = data['latitude']
          longitude = data['longitude']

          ll = new (google.maps.LatLng)(latitude, longitude)
          marker = new (google.maps.Marker)(
            position: ll
            map: map)
          map.setCenter(ll)

          google.maps.event.addListener marker, 'click', ->
            geocoder.geocode { latLng: marker.getPosition() }, (results, status) ->
              if status == google.maps.GeocoderStatus.OK
                address = results[0].formatted_address
                infowindow.setContent trucker + ' (' + data['timestamp'] + ')<br>' + address
                infowindow.open map, marker
                map.setZoom 15

          google.maps.event.trigger marker, 'click'

    loadMarker()


  realtime: ->
    geocoder = new (google.maps.Geocoder)
    bounds = new (google.maps.LatLngBounds)
    gmarkers = {}
    i = undefined

    map = new (google.maps.Map)(document.getElementById('map'),
      mapTypeId: google.maps.MapTypeId.ROADMAP)
    infowindow = new (google.maps.InfoWindow)

    $(document).on 'click', '.with-marker', ->
      google.maps.event.trigger gmarkers[$(this).data('id')], 'click'
      map.setZoom 12

    $(document).on 'click', '.fit-map', ->
      fitBounds()

    loadMarkers = ->
      $('li.with-marker').removeClass('with-marker')
      $.each gmarkers, (id, marker) ->
        marker.setMap(null)
      $.getJSON '/locations/track', (data) ->
        $.each data, (key, location) ->
          trucker_id = location['trucker_id']
          latitude = location['latitude']
          longitude = location['longitude']
          time = location['time']

          ll = new (google.maps.LatLng)(latitude, longitude)
          bounds.extend(ll)
          marker = new (google.maps.Marker)(
            position: ll
            map: map)

          google.maps.event.addListener marker, 'click', ->
            map.setZoom 18
            map.setCenter ll
            marker.setZIndex(9999)
            showInfo(marker, location)

          google.maps.event.addListener marker, 'mouseover', ->
            showInfo(marker, location)

          google.maps.event.addListener marker, 'mouseout', ->
            infowindow.close()

          gmarkers[trucker_id] = marker

          listTag = $('li[data-id=' + trucker_id + ']')
          listTag.addClass('with-marker').find('.time').html(time)

        fitBounds()

    fitBounds = ->
      map.setCenter(bounds.getCenter())
      map.fitBounds(bounds)

    showInfo = (marker, location)->
      geocoder.geocode { latLng: marker.getPosition() }, (results, status) ->
        if status == google.maps.GeocoderStatus.OK
          address = results[0].formatted_address
          infowindow.setContent location['trucker'] + ' (' + location['timestamp'] + ')<br>' + address
          infowindow.open map, marker
          highlight(location)

    highlight = (location)->
      $('ul.trigger-marker li').removeClass('active')
      elem = $('li[data-id="' + location['trucker_id'] + '"]')
      elem.addClass('active')
      $('ul.trigger-marker').animate(
        scrollTop: elem.position().top
      , 500)

    loadMarkers()
    window.clearInterval(window.realtimeGPS) if window.realtimeGPS
    window.realtimeGPS = window.setInterval loadMarkers, 1000*60*5

  history: ->
    window.clearInterval(window.realtimeGPS) if window.realtimeGPS
    bounds = new (google.maps.LatLngBounds)
    i = undefined

    map = new (google.maps.Map)(document.getElementById('map'),
      mapTypeId: google.maps.MapTypeId.ROADMAP)
    infowindow = new (google.maps.InfoWindow)

    $(document).on 'click', '.fit-map', ->
      fitBounds()

    loadMarkers = ->
      geocoder = new (google.maps.Geocoder)
      $.getJSON window.location.href, (data) ->
        $.each data, (key, location) ->
          num = key + 1
          latitude = location['latitude']
          longitude = location['longitude']

          ll = new (google.maps.LatLng)(latitude, longitude)
          bounds.extend(ll)
          marker = new (google.maps.Marker)(
            animation: google.maps.Animation.DROP
            icon: getDigitalMarker(num)
            position: ll
            map: map
            zIndex: key)

          google.maps.event.addListener marker, 'click', ->
            map.setZoom 18
            map.setCenter ll
            marker.setZIndex(9999)
            geocoder.geocode { latLng: marker.getPosition() }, (results, status) ->
              if status == google.maps.GeocoderStatus.OK
                address = results[0].formatted_address
                infowindow.setContent location['timestamp'] + '<br>' + address
                infowindow.open map, marker
              else
                infowindow.setContent location['timestamp']
                infowindow.open map, marker

          liTag = $('<li>').html(location['timestamp'])
          liTag.click ->
            google.maps.event.trigger marker, 'click'
          $('ul.timestamps').append(liTag)
        fitBounds()

    fitBounds = ->
      map.setCenter(bounds.getCenter())
      map.fitBounds(bounds)

    getDigitalMarker = (digit)->
      iconUrl = "https://chart.googleapis.com/chart?chst=d_map_pin_letter&chld="+ digit + "|FF776B|000000"
      new (google.maps.MarkerImage)(iconUrl, new (google.maps.Size)(25, 35), new (google.maps.Point)(0, 0), new (google.maps.Point)(0, 35))

    loadMarkers()


