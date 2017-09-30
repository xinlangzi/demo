window.Maintenance =

  captured: []

  init: ->
    Maintenance.captureReceipt()
    Maintenance.submit()
    Maintenance.delete()

  captureReceipt: ->
    $(document).on 'change', '#maintenance-form .camera-input', (e)->
      file = e.target.files[0]
      reader = new FileReader()
      max = $(e.target).data('max') || 10
      if file
        Maintenance.captured.push(file)
        reader.readAsDataURL(file)
      reader.onload = ->
        div = $('<div class="col-33 image">')
        div.append($('<div class="icon ion-ios-close remove">'))
        div.append($('<img>').attr('src', reader.result))
        $('.add-image').after(div)
        $('.add-image').hide() if Maintenance.captured.length >= max
        $(div).find('.remove').click ->
          div.remove()
          Maintenance.captured.splice(Maintenance.captured.indexOf(file), 1)
          $('.add-image').show() if Maintenance.captured.length < max

  submit: ->
    $(document).on 'submit', 'form#maintenance-form', (e)->
      e.preventDefault()
      fd = new FormData()
      form = $(this)
      if Maintenance.captured.length == 0
        F7H.app.alert("Please capture the receipt!", "Warning")
      else
        $(Maintenance.captured).each (index, file)->
          fd.append("files[" + index + "]", file)
        fd.append(x.name, x.value) for x in form.serializeArray()
        $.ajax
          url: form.attr('action')
          method: 'POST'
          contentType: false
          dataType: 'json'
          processData: false
          data: fd
          beforeSend: (xhr)->
            Loading()
          success: (response)->
            Phone.Views.Main.loadPage(response.location)
            ClearNotifications()
            F7H.app.addNotification
              title: 'Congratulations'
              message: response.message
            Maintenance.clearCaptured()
            Loaded()
          error: (xhr, status, error)->
            ul = $('<ul>').addClass('error-recap')
            $.each xhr.responseJSON, (index, error) ->
              error = index + 1 + ". " + error
              ul.append($('<li>').html(error))
            $('.error-messages').html(ul)
            Loaded()
  delete: ->
    $(document).on 'click', '#maintenance .delete', ->
      id = $(this).data('id')
      F7H.app.confirm 'Are you sure to delete?', '', (->
        $.ajax
          url:'/mobiles/drivers/maintenances/' + id
          type: 'DELETE'
          dataType: 'json'
          beforeSend: (xhr)->
            Loading()
          success: (response)->
            Phone.Views.Main.loadPage(response.location)
            ClearNotifications()
            F7H.app.addNotification
              title: 'Congratulations'
              message: response.message
          error: (xhr, status, error)->
            F7H.app.alert(xhr.responseText, "Warning")
            Loaded()
        return
      ), ->
        return

  clearCaptured: ->
    Maintenance.captured = []

$ ->
  Maintenance.init()
