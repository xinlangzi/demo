window.DayLog =

  init: ->
    DayLog.calendar()
    DayLog.delete()

  calendar: ->
    $('#day-log-calendar:not(.inited)').fullCalendar
      aspectRatio: 2
      height: 'auto'
      header:
        left: 'prev,next today',
        center: 'title',
        right: ''
      events: '/mobiles/drivers/day_logs.json'
      dayClick: (date, jsEvent, view)->
        url = '/mobiles/drivers/day_logs/new?date=' + date.format()
        OpenAjaxPopup(url)
      eventClick: (event)->
        url = '/mobiles/drivers/day_logs/' + event._id
        OpenAjaxPopup(url)
      eventRender: (event, element)->
        element.addClass('only-icon')
        element.find('.fc-content').remove()
        element.prepend("<i class='" + event.mobileIcon +  "'></i>")

  refreshCalendar: ->
    $('#day-log-calendar').fullCalendar( 'refetchEvents' )

  delete: ->
    $(document).on 'click', '.day-log-card .delete', ->
      id = $(this).data('id')
      card = $(this).closest('.card')
      F7H.app.confirm 'Are you sure to delete?', '', (->
        $.ajax
          url:'/mobiles/drivers/day_logs/' + id
          type: 'DELETE'
          dataType: 'json'
          beforeSend: (xhr)->
            Loading()
          success: (response)->
            ClearNotifications()
            F7H.app.addNotification
              title: 'Congratulations'
              message: response.message
            Loaded()
            CloseAjaxPopup()
            DayLog.refreshCalendar()
          error: (xhr, status, error)->
            F7H.app.alert(xhr.responseText, "Warning")
            Loaded()
        return
      ), ->
        return

$ ->
  DayLog.init()
