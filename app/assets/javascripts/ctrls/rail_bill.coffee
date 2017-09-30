window.RailBill =

  init: ->
    RailBill.observeContent()

  events: ->
    RailBill.submitToBill()

  observeContent: ->
    $('#rbfreetext').observe_field 0.1, ->
      $('#rbcontent').html($(this).val().replace(/\n/g,"<br>").replace(/\s/g, "&nbsp;"))

#### EVENT BEGIN ###
  submitToBill: ->
    $(document).on 'click', '#rail-bill', ->
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

RailBill.events()

# $(document).on 'turbolinks:load', ->
#   RailBill.init()