window.Chassis =

  events: ->
    Chassis.combine()

##Event Begin#####
  combine: ->
    $(document).on 'change', '.combine-with-container', ->
      location_select = $(this).closest('.operation-detail').find('.company-chooser')
      if $(this).is(":checked")
        location_select.val('').trigger('change').prop('disabled', true)
      else
        location_select.trigger('change').prop('disabled', false)

##Event End####
Chassis.events()