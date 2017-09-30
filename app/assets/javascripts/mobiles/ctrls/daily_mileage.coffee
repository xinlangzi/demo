window.DailyMileage =

  init: ->
    DailyMileage.submit()
    DailyMileage.diff()

  submit: ->
    $(document).on 'submit', 'form#daily-mileage-form', (e)->
      e.preventDefault()
      form = $(this)
      url = form.attr('action')
      contentType = form.attr('enctype')
      $.ajax
        url: url
        method: 'POST'
        contentType: contentType
        dataType: 'json'
        data: form.serialize()
        success: (response)->
          Phone.Views.Main.loadPage(response.location)
          ClearNotifications()
          F7H.app.addNotification
            title: 'Thank you'
            message: 'The daily mileage was successfully submitted!'
        error: (xhr, status, error)->
          ul = $('<ul>').addClass('error-recap')
          $.each xhr.responseJSON, (index, error) ->
            error = index + 1 + ". " + error
            ul.append($('<li>').html(error))
          $('.error-messages').html(ul)

  diff: ->
    $(document).on 'keyup', '.mileage', ->
      try
        start = parseFloat($('#daily_mileage_start').val())
        end = parseFloat($('#daily_mileage_end').val())
        throw 'no number' if isNaN(start) or isNaN(end)
        $('#diff').html(end - start)
      catch e
        $('#daily_mileage_end').val('')
        $('#diff').html('N/A')


$ ->
  DailyMileage.init()
