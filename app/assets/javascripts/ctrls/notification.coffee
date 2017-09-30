window.Notification =

  init: ->
    Notification.draggable()

  events: ->

  draggable: ->
    $('#notification').draggable
      handle: '.title'

  on_create: (id)->
    $.ajax
      url: '/notifications/' + id + '/load'
      type: 'GET'

  on_update: (id)->
    $.ajax
      url: '/notifications/' + id + '/reload'
      type: 'GET'

  on_destroy: (id)->
    $.ajax
      url: '/notifications/' + id + '/deleted'
      type: 'GET'

  on_toggle: (hidden)->
    if hidden
      $('#notification ul.content').hide()
      $('#notification .max-min .fa').removeClass('fa-window-minimize').addClass('fa-window-restore')
    else
      $('#notification ul.content').show()
      $('#notification .max-min .fa').removeClass('fa-window-restore').addClass('fa-window-minimize')


Notification.events()

$(document).on 'turbolinks:load', ->
  Notification.init()
