window.TextMessage =

  init: ->
    TextMessage.sendSms()

  sendSms: ->
    $(document).on 'submit', 'form#sms-form', (e)->
      e.preventDefault()
      form = $(this)
      url = form.attr('action')
      $.ajax
        url: url
        method: 'POST'
        dataType: 'json'
        data: form.serialize()
        success: (response)->
          Phone.Views.Main.loadPage(response.location)
          ClearNotifications()
          F7H.app.addNotification
            title: 'Congratulations'
            message: 'The SMS was successfully sent!'
        error: (xhr, status, error)->
          ul = $('<ul>').addClass('error-recap')
          $.each xhr.responseJSON, (index, error) ->
            error = index + 1 + ". " + error
            ul.append($('<li>').html(error))
          $('.error-messages').html(ul)

$ ->
  TextMessage.init()