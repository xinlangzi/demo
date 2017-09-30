window.Address =

  events: ->
    Address.googleMapGeocode()
    Address.autoFill()
    Address.clear()

  googleMapGeocode: ->
    $(document).on 'change', '.geocode', ->
      Address.requestValidation($(this).closest('.address-entry'))

    $(document).on 'click', '.validate-address', ->
      Address.requestValidation($(this).closest('.address-entry'))

  requestValidation: (section)->
    $(section).find('.geocoded').html('Validating address ... Please wait!')
    $(section).find('.lat').val('')
    $(section).find('.lng').val('')
    address = []
    street  = $.trim $(section).find('.street').val()
    city    = $.trim $(section).find('.city').val()
    state   = $.trim $(section).find('.state option:selected').text()
    zip     = $.trim $(section).find('.zipcode').val()
    state_zip = $.trim state + ' ' + zip

    if [11, 39, 41, 49, 55, 56].indexOf(parseInt($(section).find('.state').val())) >= 0
      $(section).find('.geocoded').html("<span class='warning'>This address is outside of the United States and cannot be validated.</span>")
    else
      address.push(street) unless street.blank()
      address.push(city) unless city.blank()
      address.push(state_zip) unless state_zip.blank()
      $.ajax
        url: '/google_map/geocode'
        type: 'GET'
        data:
          sid: $(section).attr('id')
          address: address.join(', ')

  autoFill: ->
    $(document).on 'click', '.gm-address', ->
      section = $(this).closest('.address-entry')
      parts = $(this).data('address').split('|')
      $(section).find('.street').val(parts[0])
      $(section).find('.city').val(parts[1])
      $(section).find('.state').val(parts[2])
      $(section).find('.zipcode').val(parts[3])
      $(section).find('.lat').val(parts[4])
      $(section).find('.lng').val(parts[5])

  clear: ->
    $(document).on 'click', '.clear-address', ->
      section = $(this).closest('.address-entry')
      $(section).find('.street').val('')
      $(section).find('.city').val('')
      $(section).find('.state').val('')
      $(section).find('.zipcode').val('')

Address.events()
