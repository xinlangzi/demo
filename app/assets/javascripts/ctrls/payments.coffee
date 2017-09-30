window.Payment =

  events: ->
    Payment.checkPaymentMethod()

  checkPaymentMethod: ->
    $(document).on 'change', '#payment_payment_method_id', ->
      $this = $(this)
      if $this.hasClass('payable')
        if $this.find('option:selected').text() == 'Check'
          $('#payment_number').val('').attr('disabled', true)
          $('#check_drop_down').show()
        else
          $('#payment_number').attr('disabled', false)
          $('#check_drop_down').hide()
  allWithSameInvoice: ->
    App.checkAll('line_item', false);
    class_name = $('.line_item:first').attr('class').split(' ').pop();
    App.checkAll(class_name, true);


window.TPPayablePayment =

  events: ->
    TPPayablePayment.checkPaymentMethod()

  checkPaymentMethod: ->
    $(document).on 'change', '#tp_payable_payment_method', ->
      $this = $(this)
      if $this.find('option:selected').text() == 'Check'
        $('#payment_number').val('').attr('disabled', true)
        $('#payment_issue_date_label').html('Check Date')
        $('#check_drop_down').show()
      else
        $('#payment_number').attr('disabled', false)
        $('#payment_issue_date_label').html('Transaction Date')
        $('#check_drop_down').hide()

window.TPReceivablePayment =
  events: ->
    TPReceivablePayment.checkPaymentMethod()

  checkPaymentMethod: ->
    $(document).on 'change', '#tp_receivable_payment_method', ->
      $this = $(this)
      if $this.find('option:selected').text() == 'Check'
        $('#payment_issue_date_label').html('Check Date')
      else
        $('#payment_issue_date_label').html('Transaction Date')

window.BatchPayablePayment =
  events: ->
    BatchPayablePayment.checkPaymentMethod()
    BatchPayablePayment.observeBalances()

  checkPaymentMethod: ->
    $(document).on 'change', '.batch-payment-method', ->
      $this = $(this)
      $payment_nubmer = $this.closest('tr').find('.batch-payment-number')
      if $this.find('option:selected').text() == 'Check'
        $payment_nubmer.val('')
        $payment_nubmer.attr('disabled', true)
      else
        $payment_nubmer.attr('disabled', false)

  observeBalances: ->
    submitForm = (form)->
      $.ajax
        url: form.attr('action')
        type: 'POST'
        dataType: 'script'
        data: form.serialize()

    $(document).on 'change', '.set-cleared-date', ->
      submitForm($(this).closest('form'))

    $(document).on 'keyup', 'input[aria-controls="unclear_payment"]', ->
      submitForm($(this).closest('form'))

Payment.events()
TPPayablePayment.events()
TPReceivablePayment.events()
BatchPayablePayment.events()
