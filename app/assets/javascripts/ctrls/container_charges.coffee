window.ContainerCharge =

  events: ->
    ContainerCharge.totalAmount()

  totalAmount: ->
    $(document).on 'change', '.cc_amount', ->
      $table = $(this).closest('table')
      $total = $table.find('.cc_total')
      values = for elem in $table.find('.cc_amount')
        val = parseFloat($(elem).val())
        $(elem).val(val)
        val
      sum = values.reduce (x, y) -> x + y
      ret = if isNaN(sum) then 'Non-numeric' else '$' + sum.toFixed(2)
      $total.html(ret)
      $total.closest('th').effect("highlight", {}, 5000)

ContainerCharge.events()