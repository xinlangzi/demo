window.TextMessage =

  init: ->
    TextMessage.observeContent()

  observeContent: ->
    $('.sms-driver-message').observe_field 0.2, ->
      $this = $(this)
      if $this.val().length >= 140
        $this.val($this.val().substring(0, 140)).trigger('change').effect("highlight", {}, 1000)

$(document).on 'turbolinks:load', ->
  TextMessage.init()