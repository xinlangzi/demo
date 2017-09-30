window.Calendar =
  init: ->
    Calendar.switchDate()

  switchDate: ->
    $("#calendar-date-picker").datepicker
      changeMonth: true
      changeYear: true
      onSelect: (dateText, inst) ->
        window.location = '/containers/calendar?date=' + dateText

$(document).on 'turbolinks:load', ->
  Calendar.init()