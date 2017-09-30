window.Operation =

  events: ->
    Operation.datepicker()

  datepicker: ->
    $(document).on "focus", ".operation-at:not(.hasDatepicker)", ->
      $.datepicker.setDefaults dateFormat: "yy-mm-dd"
      showTime = $(this).data("time-required")
      $(this).datetimepicker
        changeMonth: true
        changeYear: true
        showTimepicker: showTime
        beforeShow: (input, dp_inst, tp_inst) ->
          isBlank = $.isBlank($(input).val())
          timeRequired = $(input).data("time-required")
          if isBlank and timeRequired
            tp_inst.blankText = "Please specify time!"
            tp_inst.timeBlank = true

        onClose: (dateText, dp_inst, tp_inst) ->
          dateText = dateText.replace(/\s.*/, "")  if tp_inst.timeBlank
          if !$.isBlank(dateText) && tp_inst.changed
            confirmation = $(this).data("confirm")
            if $.isBlank(confirmation) || confirm(confirmation)
              $.ajax
                url: $(this).data("url")
                dataType: 'script'
                type: "POST"
                data:
                  datetime: dateText

  refresh: (id)->
    if $('.operate_operation_' + id).length > 0
      $.ajax
        url: '/operations/' + id + '/reload'
        type: 'GET'

Operation.events()
