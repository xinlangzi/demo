window.Adjustment =

  init: ->
    Adjustment.showRelatedAdjustments()

  events: ->
    Adjustment.paymentLineItemListener()

  paymentLineItemListener: ->
    $(document).on 'change', '.line_item_check_box', ->
      Adjustment.showRelatedAdjustments()

  showRelatedAdjustments: ->
    selected = []
    $('tr.adjustment').hide()
    $('.line_item_check_box').each ->
      $this = $(this)
      id = $this.data('id')
      if $this.is(':checked')
        $('tr[data-invoice-id='+id+']').show()
        selected.push(id)
    $('tr.adjustment').each ->
      $item = $(this)
      $item.find('input[type=checkbox]').prop('checked', false) unless $item.data('invoice-id') in selected

Adjustment.events()

$(document).on 'turbolinks:load', ->
  Adjustment.init()