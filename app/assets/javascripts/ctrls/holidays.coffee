window.Holiday =

  init: ->
    Holiday.calendar()

  calendar: ->
    $('#holidays-calendar:not(.inited)').fullCalendar
      header:
        left: 'prev,next today',
        center: 'title',
        right: ''
      events: '/holidays.json'
      selectable: true
      selectHelper: true
      editable: true
      droppable: true
      select: (start, end, jsEvent, view)->
        title = prompt('Holiday Name:')
        if title
          $.post("/holidays.json", {title: title, date: start.format()}
          ).done (data) ->
            $("#holidays-calendar").fullCalendar "renderEvent", data , true

      eventDrop: (event, dayDelta, revertFunc)->
        $.ajax
          url: '/holidays/' + event._id
          type: 'PUT'
          data: { start: event.start.format() }

      eventResize: (event, delta, revertFunc)->
        $.ajax
          url: '/holidays/' + event._id
          type: 'PUT'
          data: { start: event.start.format(), end: event.end.format() }

      eventClick: (event)->
        $.ajax(
          url: '/holidays/' + event._id
          type: 'DELETE'
        ).done (data)->
          $("#holidays-calendar").fullCalendar('removeEvents', data.id)

    $('#holidays-calendar').addClass('inited')

$(document).on 'turbolinks:load', ->
  Holiday.init()
