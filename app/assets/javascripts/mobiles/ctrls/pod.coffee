window.Pod =

  signagure: null

  init: ->
    Pod.open()
    Pod.timePicker()
    Pod.chooseReceiver()
    Pod.initCanvas()
    Pod.done()
    Pod.clear()
    Pod.submit()
    Pod.rotate()
    Pod.intact()
    Pod.submitted()

  open: ->
    $(document).on 'click', '.open-pod', ->
      F7H.app.popup('.popup-pod')

  timePicker: ->
    $(document).on 'focus', '.timePicker', ->
      $(this).mobiscroll().time
        theme: 'ios'
        mode: 'mixed'
        steps:
          minute: 5
  chooseReceiver: ->
    $(document).on 'click', '.choose-receiver', ->
      $('#pod_email').val $(this).find('.email').html()

  initCanvas: ->
    canvas = document.querySelector("canvas")
    canvas.width = window.screen.width - 15
    if window.screen.height > window.screen.width
      canvas.height = window.screen.height*0.3
      canvas.style.marginTop = "10%"
    else
      canvas.height = window.screen.height*0.6
      canvas.style.marginTop = "2%"
    Pod.signagure = new SignaturePad(canvas)

  done: ->
    $(document).on 'click', '#pod-done', ->
      $('img#signature').attr('src', Pod.signagure.toDataURL())
      if Pod.signagure.isEmpty()
        $('input#signature-data').val('')
      else
        $('input#signature-data').val(Pod.signagure.toDataURL())
      F7H.app.confirm 'Are you ready to send POD?', '', (->
        $('form#pod-form').submit()
        return
      ), ->
        return

  clear: ->
    $(document).on 'click', '#pod-clear', ->
      $('input#signature-data').val('')
      Pod.signagure.clear()

  submit: ->
    $(document).on 'submit', 'form#pod-form', (e)->
      e.preventDefault()
      if $('input#signature-data').val().length == 0
        F7H.app.alert("Customer's signature is blank!", "Warning")
      else
        form = $(this)
        url = form.attr('action')
        contentType = form.attr('enctype')
        $.ajax
          url: url
          method: 'POST'
          contentType: contentType
          dataType: 'json'
          timeout: 10000
          data: form.serialize()
          success: (response)->
            Phone.Views.Main.back()
            Pod.markStatusSubmitted()
            ClearNotifications()
            $('.popup-pod-success .msg').html(response.message)
            F7H.app.popup('.popup-pod-success')
          error: (xhr, status, error)->
            $('.picker-modal .content-block').html('')
            if status == 'timeout'
              title = $('<h3 class="color-red">').html('Oops! Timeout to upload POD! Try it again!')
              $('.picker-modal .content-block').append(title)
            else
              title = $('<h3 class="color-red">').html('Failed to upload POD')
              ul = $('<ul>').addClass('errors')
              $.each xhr.responseJSON, (index, error) ->
                ul.append($('<li>').html(error))
              $('.picker-modal .content-block').append(title).append(ul)
            F7H.app.pickerModal('.picker-modal')
  submitted: ->
    $(document).on 'click', '#pod-submitted', (e)->
      e.preventDefault()
      F7H.app.alert('Please contact dispatch', '')

  markStatusSubmitted: ->
    $('#pod-submitted').removeClass('hidden')
    $('#new-pod').addClass('hidden')

  intact: ->
    $(document).on 'change', '#intact', ->
      if $(this).is(":checked")
        $('.yes-intact').removeClass('hidden')
        $('.no-intact').addClass('hidden')
      else
        $('.yes-intact').addClass('hidden')
        $('.no-intact').removeClass('hidden')

  rotate: ->
    if window.DeviceOrientationEvent
      window.addEventListener "orientationchange", (event)->
        setTimeout( ->
          Pod.initCanvas()
        ,1000)

$ ->
  Pod.init()
