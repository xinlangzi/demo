window.Menu =
  init: ->
    Menu.activate()

  activate: ->
    $menu = $('.menu')
    $menu.find('.' + $menu.data('active')).addClass('active') if $menu.data('active')


$(document).on 'turbolinks:load', ->
  Menu.init()
