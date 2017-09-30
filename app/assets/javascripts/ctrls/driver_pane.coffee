window.DriverPane =
  timer: null

  init: ->
    DriverPane.initSort()
    DriverPane.hideToggleVacationTip()

  events: ->
    DriverPane.dateOnTab()
    DriverPane.sortDrivers()
    DriverPane.toggleVacationTip()
    DriverPane.draggableDriver()

  exists: ->
    $('#dddrivers').exists()

  getCurDate: ->
    $('#dddrivers').attr('data-date')

  setCurDate: (date)->
    $('#dddrivers').attr('data-date', date)

  delayLoad: (date)->
    if DriverPane.timer == null
      DriverPane.timer = setTimeout( ->
        DriverPane.reload(date)
      , 1500)

  clearTimer: ->
    clearTimeout(DriverPane.timer)
    DriverPane.timer = null

  load: (date)->
    if DriverPane.exists()
      curDate = DriverPane.getCurDate()
      if date==curDate
        $.ajax(
          url: '/drivers/summary?date=' + curDate
          type: 'GET'
          dataType: 'script'
        ).done ->
          DriverPane.init()

  reload: (date)->
    if DriverPane.exists() && date != DriverPane.getCurDate()
      DriverPane.setCurDate(date)
      $('#drive-date').html(date)
      DriverPane.load(date)

  hideToggleVacationTip: ->
    $('.toggle-vacation-tip').hide() if $.cookie('hide-toggle-vacation-tip')

  markActive: (item)->
    $('.sort-widget a').removeClass('red')
    item.addClass('red')

  storeCookie: (value)->
    $.cookie('sort-driver-by', value)

  getCookie: ->
    $.cookie('sort-driver-by') || '.sort-widget .by-mileages'

  initSort: ->
    $(DriverPane.getCookie()).trigger('click')

  droppableDriver: ->
    $(".droppable-driver").droppable
      activeClass: "active-state"
      hoverClass: "hover-state"
      drop: (event, ui) ->
        draggable = ui.draggable
        available = !draggable.hasClass('unavailable')
        name = draggable.data('name')
        if available || confirm( name + ' is scheduled for day off. Are you sure you want to proceed?')
          params = {}
          params["tid"] = draggable.attr("ref")
          params["id"] = $(this).data("id")
          params["target"] = $(this).data("target")
          params["date"] = $('#dddrivers').data("date")
          $.ajax
            url: "/drivers/assign"
            type: "GET"
            data: $.param(params)

###### EVENT BEGIN ####
  dateOnTab: ->
    $(document).on 'mouseover', '.date-tab', ->
      date = $(this).data('date')
      if date != DriverPane.getCurDate()
        if $(this).find('.containers-table:visible').length > 0
          DriverPane.delayLoad(date)
    $(document).on 'mouseleave', '.date-tab', ->
      DriverPane.clearTimer()

  draggableDriver: ->
    $(document).on 'mouseover', '#dddrivers', ->
      $("#dddrivers div.draggable").draggable
        scroll: true
        appendTo: "body"
        helper: "clone"
        cursor: "move"
        start: (event, ui) ->
          driver_id = $(this).data("li")
          date = $('#dddrivers').data("date")
          DriverPane.droppableDriver()
          App.driver_pane.dragging(date, driver_id)

        stop: (event, ui) ->
          driver_id = $(this).data("li")
          date = $('#dddrivers').data("date")
          App.driver_pane.dragged(date, driver_id)

  toggleVacationTip: ->
    $(document).on 'click', '.toggle-vacation-tip a', ->
      $.cookie('hide-toggle-vacation-tip', true)
      DriverPane.hideToggleVacationTip()

  sortDrivers: ->
    $(document).on 'click', '.sort-widget a', ->
      DriverPane.markActive($(this))

    $(document).on 'click', '.sort-widget .by-name', ->
      DriverPane.storeCookie('.sort-widget .by-name')
      $('.driver-pane .driver-to-assign').tsort '.name',
        order: 'asc'
        attr: 'class'
      , '.name',
        order: 'asc'

    $(document).on 'click', '.sort-widget .by-status', ->
      DriverPane.storeCookie('.sort-widget .by-status')
      $('.driver-pane .driver-to-assign').tsort '.status',
        order: 'asc'
        attr: 'class'
      , '.name',
        order: 'asc'

    $(document).on 'click', '.sort-widget .by-mileages', ->
      DriverPane.storeCookie('.sort-widget .by-mileages')
      $('.driver-pane .driver-to-assign').tsort '.miles',
        order: 'asc'
      , '.name',
        order: 'asc'

    $(document).on 'click', '.sort-widget .by-score', ->
      DriverPane.storeCookie('.sort-widget .by-score')
      $('.driver-pane .driver-to-assign').tsort '.score',
        order: 'desc'
      , '.name',
        order: 'desc'
###### EVENT END ####

DriverPane.events()

$(document).on 'turbolinks:load', ->
  DriverPane.init()
