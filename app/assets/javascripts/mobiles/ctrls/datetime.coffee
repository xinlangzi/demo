window.Datetime =

  init: ->
    $(document).on 'focus', 'input.only_date', ->
      $(this).mobiscroll().date
        theme: 'ios'
        dateFormat: 'yy-mm-dd'
        onBeforeShow: (inst)->
          inst.oriVal = inst.getVal() || ""
        onSelect: (valueText, inst)->
          if(inst.oriVal.toString() != inst.getVal().toString())
            Datetime.operate($(this))

    $(document).on 'focus', 'input.date_time', ->
      $(this).mobiscroll().datetime
        theme: 'ios'
        dateFormat: 'yy-mm-dd'
        stepMinute: 5
        onBeforeShow: (inst)->
          inst.oriVal = inst.getVal() || ""
        onSelect: (valueText, inst)->
          if(inst.oriVal.toString() != inst.getVal().toString())
            Datetime.operate($(this))

  operate: (input)->
    return unless input.data('url')
    method = input.data('method') || 'POST'
    $.ajax
      url: input.data('url')
      method: method
      dataType: 'json'
      data:
        datetime: input.val()
        date: input.val()
      success: (response)->
        ClearNotifications()
        F7H.app.addNotification
          title: 'Congratulations'
          message: response.message
        input.next().removeClass().addClass(response.alter_status)
      error: (xhr, status, error)->
        F7H.app.alert(xhr.responseJSON.error, "Warning")
        input.val('')

$ ->
  Datetime.init()