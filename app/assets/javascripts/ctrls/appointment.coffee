window.Appointment =

  events: ->
    Appointment.toggleDelayOwner()


  toggleDelayOwner: ->
    $(document).on 'change', '.delay-by-trucker', ->
      total = parseFloat($('.total-moves').html())
      lates = $('.delay-by-trucker:checked').length
      ratio = (lates/total*100).round(2) + "%"
      $('.total-lates').html(lates).effect("highlight", {}, 2000)
      $('.late-ratio').html(ratio).effect("highlight", {}, 2000)


Appointment.events()
