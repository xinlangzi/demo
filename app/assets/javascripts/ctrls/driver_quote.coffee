window.DriverQuote =

  ajaxLoadForm: ->
    if $('.ajax-driver-quote').exists()
      $.ajax
        url: '/driver_quotes'
        dataType: 'script'
        type: 'GET'

  geoAddress: ->
    $(document).on 'focus', 'input.geo-address', ->
      $(this).geocomplete
        country: 'us'

    $(document).on 'blur', 'input.geo-address', ->
      form = $(this).closest('form')
      setTimeout( ->
        DriverQuote.query(form)
      , 500)

  railRoad: ->
    $(document).on 'change', 'select.rail-road', ->
      DriverQuote.query($(this).closest('form'))

  remove: ->
    $(document).on 'click', '.driver-quotes .remove', ->
      $(this).closest('form').remove()
      DriverQuote.total()

  query: (form)->
    $.ajax
      url: '/driver_quotes'
      type: "POST"
      data: $(form).serialize()
      beforeSend: (xhr)->
        $(form).find('.rates').html('Calculating...')
      complete: (xhr, status)->
        DriverQuote.total()

  total: ->
    total = 0.0
    $('.sum').each (index, item)->
      sum = $(item).text().replace( /\,|\$/g,'')
      total += parseFloat(sum)
    $('.total .amount').html(total.round(2).toFixed(2).commafy())

  initBox: ->
    $(document).on 'click', '#mail-contact', ->
      $('#driverbox .feedback').hide()
      $('#driverbox .form').show()
      $('#driverbox').show()
      $('#fade').show()
      $('#driver_name').focus()
      $('#driver_quotes').prop('checked', false)

    $(document).on 'click', '#mail-quotes', ->
      $('#driverbox .feedback').hide()
      $('#driverbox .form').show()
      $('#driverbox').show()
      $('#fade').show()
      $('#driver_name').focus()
      $('#quote_keys').val($('.quote-key').valList())
      $('#driver_quotes').prop('checked', true)

$ ->
  DriverQuote.ajaxLoadForm()
  DriverQuote.geoAddress()
  DriverQuote.railRoad()
  DriverQuote.remove()
  DriverQuote.initBox()