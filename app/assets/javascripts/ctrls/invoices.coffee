window.Invoice =

  events: ->
    Invoice.autoNumber()
    Invoice.exportQuickBooks()

  autoNumber: ->
    $(document).on 'change', '.invoice-auto-number', ->
      invoice_number = $(this).closest('td').find('.invoice-number');
      if $(this).is(':checked')
        invoice_number.val('').attr('disabled', true)
      else
        invoice_number.attr('disabled', false)

  exportQuickBooks: ->
    $(document).on 'click', '[data-behavior~=export-to-quickbooks]', (event) ->
      event.preventDefault()
      params = $.param({
        filter: {
          id_in: $('.invoice-ids:checked').valList()
        }
      })
      window.location.href = "#{window.location.pathname}.iif?#{params}"

Invoice.events()