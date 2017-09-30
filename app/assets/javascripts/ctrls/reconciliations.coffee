window.Reconciliation =

  init: ->
    Reconciliation.paymentsByCompany()

  events: ->
    Reconciliation.toggleHighlight()

  toggleHighlight: ->
    $(document).on 'click', '#reconciliation [data-behavior~=toggle-highlight]', (event) ->
      $this = $(this)
      $this.parents('tr').toggleClass('highlight')

  paymentsByCompany: ->
    $('.payments-by-company').each ->
      unless $.fn.dataTable.isDataTable($(this))
        $(this).DataTable
          bPaginate: false
          aaSorting: [[4, "asc"]]
          aoColumns: [null, null, null, { sSortDataType: "cell", sType: "numric" }, null ]


Reconciliation.events()

$(document).on 'turbolinks:load', ->
  Reconciliation.init()