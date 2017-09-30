window.ReceivableQuote =

  events: ->
    ReceivableQuote.request()
    ReceivableQuote.choose()

#### EVENT BEGIN ###
  request: ->
    $(document).on 'click', 'a#calculate-receivables', (event)->
      $form = $('#container-form')
      $.ajax(
        url: "/receivable_quotes/cache"
        type: "PATCH"
        dataType: 'script'
        data: $form.serialize()
      ).done ->
        $.ajax
          url: "/receivable_quotes/query"
          type: "GET"
          dataType: 'script'
  choose: ->
    $(document).on 'change', '#calculate-receivables-form input[name="target_id"]', ->
      $('.charge-item').prop('disabled', true)
      $(this).closest('tr').find('.charge-item').prop('disabled', false)
#### EVENT END ###

ReceivableQuote.events()
