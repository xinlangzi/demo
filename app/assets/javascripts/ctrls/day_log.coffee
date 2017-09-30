window.DayLog =

  init: ->
    DayLog.calendar()

  calendar: ->
    $('#day-log-calendar:not(.inited)').fullCalendar
      aspectRatio: 2
      height: 'auto'
      header:
        left: 'prev,next today',
        center: 'title',
        right: ''
      events: '/truckers/' + $('#day-log-calendar').data('id') + '/day_logs.json'
      dayClick: (date, jsEvent, view)->
        id = $('#day-log-calendar').data('id')
        url = '/truckers/' + id + '/day_logs/new?date=' + date.format()
        App.newPopup(url, 'DayLog', 800, 650, 0, 0)
      eventClick: (event)->
        id = $('#day-log-calendar').data('id')
        url = '/truckers/' + id + '/day_logs/' + event._id
        App.newPopup(url, 'DayLog', 800, 650, 0, 0)
  renderCalender: ->
    setTimeout( ->
      $('#day-log-calendar').fullCalendar('render')
    , 500)




  refreshCalendar: ->
    window.opener.$('#day-log-calendar').fullCalendar('refetchEvents')


$(document).on 'turbolinks:load', ->
  DayLog.init()
