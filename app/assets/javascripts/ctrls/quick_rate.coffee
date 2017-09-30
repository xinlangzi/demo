window.QuickQuote =

  events: ->
    QuickQuote.receivable()
    QuickQuote.payable()

  receivable: ->
    submit = (form)->
      blankField = $(form).find('input.required:blank,select.required:blank').length > 0
      if blankField
        $(form).next('.quote').html('')
        return
      $.ajax
        url: $(form).attr('action')
        type: $(form).attr('method')
        data: $(form).serialize()
        beforeSend: (xhr)->
          $(form).next('.quote').html('<center>Calculating Customer Quote</center>')

    $(document).on 'change', '#ar-rate form', ->
      form = $(this)
      setTimeout( ->
        submit(form)
      , 500)

    $(document).on 'focus', 'input.ar-geo-address', ->
      $(this).geocomplete(
        country: 'us'
      ).bind "geocode:result", (event, result)->
        $(this).trigger('change')

    $(document).on 'keyup', 'input.new-percent', ->
      total = parseFloat($('#ar-rate .total').html().replace(/\$|\,/g, ''))
      percent = parseFloat($(this).val()||'0')/100.0
      baseRate = (total/(1 + percent)).round(2)
      fuelAmount = total - baseRate
      $('#ar-rate .new-base-rate').html('$' + baseRate.toLocaleString())
      $('#ar-rate .new-fuel-amount').html('$' + fuelAmount.toLocaleString())

  payable: ->
    submit = (form)->
      blankField = $(form).find('input.required:blank,select.required:blank').length > 0
      if blankField
        $(form).next('.quote').html('')
        return
      $.ajax
        url: $(form).attr('action')
        type: $(form).attr('method')
        data: $(form).serialize()
        beforeSend: (xhr)->
          $(form).next('.quote').html('<center>Calculating Driver Quote</center>')

    $(document).on 'change', '#ap-rate form', ->
      form = $(this)
      setTimeout( ->
        submit(form)
      , 500)

QuickQuote.events()
