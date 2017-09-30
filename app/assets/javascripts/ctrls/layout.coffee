window.Layout =

  init: ->
    Layout.default()
    Layout.vacation()
    Layout.calendar()

  default: ->
    $('.default-ui-layout').each ->
      eastWidth = $(this).find('.ui-layout-east').data('width')
      westWidth = $(this).find('.ui-layout-west').data('width')
      options = {}
      options.east__minSize = eastWidth if eastWidth
      options.west__minSize = westWidth if westWidth
      $(this).layout(options)

  vacation: ->
    $('#vacation-calendar-layout').layout() if $('#vacation-calendar-layout').length > 0

  calendar: ->
    if $("#calendar-layout").length > 0
      main = $("#main")
      main.css "height", main.css("min-height")
      outerLayout = $("#calendar-layout").layout
        stateManagement__enabled: true
        west__togglerLength_closed: 100
        west__togglerLength_open: 100
        west__minSize: 275
        west__togglerContent_open: "<div class=\"toggleDriverPanel\" title=\"Close Driver Panel\">&#8249;</div>"
        west__togglerContent_closed: "<div class=\"toggleDriverPanel\" title=\"Open Driver Panel\">&#8250;</div>"
      outerLayout.panes.center.layout
        stateManagement__enabled: false

$(document).on 'turbolinks:load', ->
  Layout.init()
