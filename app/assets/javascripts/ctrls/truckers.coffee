window.Trucker =

  events: ->
    Trucker.checkTasks()

  init: ->
    Trucker.draggleTrucker()
    Trucker.vacationCalendar()
    Trucker.multiTasks()

  ### BEGINS EVENTS ####
  checkTasks: ->
    $(document).on 'change', 'select.hired-tasks', ->
      $.ajax
        url: '/truckers/' + $(this).data('id') + '/tasks'
        type: 'PATCH'
        dataType: 'script'
        data:
          type: 'hired'
          tasks: $(this).val()
    $(document).on 'change', 'select.terminated-tasks', ->
      $.ajax
        url: '/truckers/' + $(this).data('id') + '/tasks'
        type: 'PATCH'
        dataType: 'script'
        data:
          type: 'terminated'
          tasks: $(this).val()
  #####END EVENTS #####

  multiTasks: ->
    $('select.hired-tasks, select.terminated-tasks').multiselect
      selectedList: 10
      minWidth: '150'
      checkAllText: "All"
      uncheckAllText: "None"
      noneSelectedText: "Check if Complete"

  draggleTrucker: ->
    $('.draggable-trucker').draggable
      zIndex: 9999
      appendTo: "body"
      helper: "clone"
      cursor: "auto"
      revert: true

  vacationCalendar: ->
    $('#my-vacations:not(.inited)').fullCalendar
      header:
        left: 'prev,next today',
        center: 'title',
        right: ''
      events: '/vacations.json'

    $('#my-vacations:not(.inited)').addClass('inited')

    $('#vacation-calendar:not(.inited)').fullCalendar
      header:
        left: 'prev,next today',
        center: 'title',
        right: ''
      events: '/vacations.json'
      editable: true
      droppable: true
      drop: (date, jsEvent, ui)->
        $.post("/vacations.json", {user_id: $(this).data('id'), date: date.format() }
        ).done (data) ->
          if data.id
            $("#vacation-calendar").fullCalendar "renderEvent", data , true

      eventDrop: (event, dayDelta, revertFunc)->
        $.ajax
          url: '/vacations/' + event._id
          type: 'PUT'
          data: { start: event.start.format() }

      eventResize: (event, delta, revertFunc)->
        $.ajax
          url: '/vacations/' + event._id
          type: 'PUT'
          data: { start: event.start.format(), end: event.end.format() }

      eventClick: (event)->
        $.ajax(
          url: '/vacations/' + event._id + '/adjust'
          type: 'GET'
        ).done (data)->
          $("#vacation-calendar").fullCalendar 'removeEvents', data.id
          if data.persisted
            $("#vacation-calendar").fullCalendar "renderEvent", data , true

    $('#vacation-calendar:not(.inited)').addClass('inited')

Trucker.events()

$(document).on 'turbolinks:load', ->
  Trucker.init()
