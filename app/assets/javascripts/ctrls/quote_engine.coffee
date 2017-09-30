window.QuoteEngine =

  events: ->
    QuoteEngine.saveCharge()

  saveCharge: ->
    $(document).on 'click', '.save-charge', ->
      $this = $(this)
      $form = $("<form></form>")
      $this.closest('td').find("input").each (index, input)->
        $(input).clone().appendTo($form)
      $.ajax
        url: '/quote_engines/save_charges'
        type: 'POST'
        dataType: 'script'
        data: $form.serialize()

QuoteEngine.events()