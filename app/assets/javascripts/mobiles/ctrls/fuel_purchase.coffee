window.FuelPurchase =

  init: ->
    FuelPurchase.captureReceipt()
    FuelPurchase.submit()

  captureReceipt: ->
    $(document).on 'change', '#capture-receipt', (e)->
      reader = new FileReader()
      reader.onload = ->
        $("#receipt").attr('src', reader.result)
      if e.target.files[0]
        reader.readAsDataURL(e.target.files[0])
        $('form#fuel-purchase-form input[type=submit]').prop('disabled', false)
  submit: ->
    $(document).on 'submit', 'form#fuel-purchase-form', (e)->
      e.preventDefault()
      if $('img#receipt').attr('src') == undefined
        F7H.app.alert("Please capture the receipt!", "Warning")
      else
        form = $(this)
        formData = new FormData($(this)[0]);
        url = form.attr('action')
        # contentType = form.attr('enctype')
        $.ajax
          url: url
          method: 'POST'
          # contentType: contentType
          dataType: 'json'
          contentType: false
          processData: false
          data: formData
          beforeSend: (xhr)->
            Loading()
          success: (response)->
            Phone.Views.Main.loadPage(response.location)
            ClearNotifications()
            F7H.app.addNotification
              title: 'Thank you'
              message: 'The fuel purchase with receipt was successfully submitted!'
            Loaded()
          error: (xhr, status, error)->
            ul = $('<ul>').addClass('error-recap')
            $.each xhr.responseJSON, (index, error) ->
              error = index + 1 + ". " + error
              ul.append($('<li>').html(error))
            $('.error-messages').html(ul)
            Loaded()
$ ->
  FuelPurchase.init()