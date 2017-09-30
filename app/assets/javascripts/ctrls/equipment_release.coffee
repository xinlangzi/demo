window.EquipmentRelease =

  init: ->
    EquipmentRelease.observeContent()

  events: ->
    EquipmentRelease.request()

  observeContent: ->
    $('#erfreetext').observe_field 0.1, ->
      $('#ercontent').html($(this).val().replace(/\n/g,"<br>").replace(/\s/g, "&nbsp;"))

#### EVENT BEGIN ###
  request: ->
    $(document).on 'click', '#equipment-release', ->
      link = $(this)
      name = link.html()
      link.html("Please wait...").prop('disabled', true)
      $.ajax
        url: link.data('url')
        type: 'PATCH'
        dataType: 'script'
        data: link.closest('form').serialize()
        success: ->
          link.html(name).prop('disabled', false)

#### EVENT END ###

EquipmentRelease.events()

# $(document).on 'turbolinks:load', ->
#   EquipmentRelease.init()