window.Container =

  init: ->
    Container.sortOperations()
    Container.dealOperationPos()
    Container.dealLastOperation()

  events: ->
    Container.lock()
    Container.addBobtailFee()
    Container.addCharge()
    Container.changeChargeType()
    Container.addOperation()
    Container.checkAppt()
    Container.checkWarnings()
    Container.companyChooser()
    Container.customerChange()
    Container.highlightOperationPayable()
    Container.onceTrucker()
    Container.removeCharge()
    Container.sslineChange()
    Container.triaxleListener()
    Container.truckerChooser()
    Container.typesOnSize()
    Container.warningOnDeleteOperation()


#### Once Called #####
  dealLastOperation: ->
    $(".trucker-select").removeClass "hidden"
    $(".trucker-select:last").addClass "hidden"
    $(".trucker-select:last trucker-chooser").val('')
    $(".add-charge").removeClass "hidden"
    $(".add-charge:last").addClass "hidden"

  dealOperationPos: ->
    $(".operation_pos").each (index, elem) ->
      $(elem).val index + 1

  sortOperations: ->
    $("#operations.sortable").sortable stop: (event, ui) ->
      Container.dealOperationPos()
      Container.dealLastOperation()

#### inner method #####

  triggerLastTruckerChange: (chooser)->
    choosers = $('.trucker-chooser')
    number = choosers.length
    lastSecond = $(choosers[number - 2])
    choosers.last().trigger('change') if chooser.attr('id') == lastSecond.attr('id')

  findTrucker: (chooser)->
    choosers = $('.trucker-chooser')
    number = choosers.length
    chooser = $(choosers[number - 2]) if chooser.attr('id') == choosers.last().attr('id')
    return chooser

###### Events Trigger #######
  lock: ->
    $(document).on "change", ".lock-container", ->
      id = $(this).val()
      if $(this).is(':checked')
        url = '/containers/' + id + '/lock'
      else
        url = '/containers/' + id + '/unlock'
      $('input[value="' + id + '"]').prop('checked', $(this).is(':checked'))
      if $(this).data('ajax')
        $.ajax
          url: url
          type: 'GET'
          dataType: 'script'
          data:
            reload: $(this).data('reload')
      else
        window.location.href = url

  companyChooser: ->
    $(document).on "change", ".company-chooser", ->
      value = $(this).val() || 0
      $.ajax
        url: "/companies/" + value + "/choose"
        type: "GET"
        data:
          select_id: $(this).attr('id')

  addOperation: ->
    $(document).on "click", ".add-operation", ->
      array = $(this).closest("form").serializeArray().filter (item, index)->
        item.name != '_method'
      $.ajax
        url: "/operations"
        type: "POST"
        data: $.param(array)

  addCharge: ->
    $(document).on 'click', '.add-charge', ()->
      $this = $(this)
      operation_detail = $this.closest('.operation-detail')
      trucker_chooser = Container.findTrucker(operation_detail.find('.trucker-chooser'))
      company_id = trucker_chooser.val()
      unless company_id.blank()
        params = {}
        params["company_id"] = company_id
        params["uid"] = operation_detail.find('.uid').val()
        params["chargable_id"] = $this.data('charge-id')
        params["chargable_type"] = "PayableCharge"
        params["tbody_id"]       = $('table.payable-container-charges').find('tbody').attr('id')
        $.ajax({
          url: '/payable_container_charges/new',
          type: 'GET',
          data: $.param(params)
        })

  changeChargeType: ->
    $(document).on 'change', '.new-charge-type', ->
      key = $(this).data('key')
      type = $(this).data('type')
      data = $(this).closest('form').serializeArray()
      data.push({ name: 'key', value: key })
      data.push({ name: 'type', value: type })
      $.ajax({
        url: "/" + type + "/changed"
        type: 'PATCH'
        data: data
      })

  addBobtailFee: ->
    $(document).on 'click', '.add-bobtail', ()->
      $this = $(this)
      operation_detail = $this.closest('.operation-detail')
      trucker_chooser = Container.findTrucker(operation_detail.find('.trucker-chooser'))
      company_id = trucker_chooser.val()
      params = {}
      if company_id
        params["company_id"]     = company_id
        params["uid"]            = operation_detail.find('.uid').val()
        params["chargable_id"]   = $this.data('charge-id')
        params["chargable_type"] = "PayableCharge"
        params["tbody_id"]       = $('table.payable-container-charges').find('tbody').attr('id')
        $.ajax({
          url: '/payable_container_charges/new',
          type: 'GET',
          data: $.param(params)
        })

  removeCharge: ->
    $(document).on 'click', '.remove-charge', ->
      $this = $(this)
      $row = $this.closest('tr')
      $row.find('.delete-it').val('1')
      $row.find('.cc_amount').val(0).trigger('change')
      $row.hide()

  checkWarnings: ->
    $(document).on "change", '.check-warning', ->
      form = $(this).closest("form")
      url = form.attr('action')
      $.post(url, form.serialize() + "&tmpl=warning")

  checkAppt: ->
    $(document).on "mouseover", ".check-appt", ->
      $this = $(this)
      $this.attr('disabled', true)
      $.ajax(
        url: '/avail_stats/appt_range'
        type: 'GET'
      ).done (data)->
        $this.attr('disabled', false)
        $this.datepicker "destroy"
        $this.datepicker(
          minDate: data.from
          maxDate: data.to
          beforeShowDay: (date)->
            [ data.disabled.indexOf($.datepicker.formatDate('yy-mm-dd', date)) == -1 ]
        ).removeClass('check-appt')

  onceTrucker: ->
    $(document).on 'change', '#once-trucker select', ()->
      $this = $(this)
      val = $this.val()
      text = $this.find("option:selected").text()
      for elem in $('.trucker-chooser')
        $elem = $(elem)
        unless $elem.prop("disabled")
          $elem.val(val).trigger('change')
          $elem.data('chosen').single_set_selected_text(text)
      Container.dealLastOperation()

  truckerChooser: ->
    $(document).on 'change', '.trucker-chooser', ()->
      it = $(this)
      text = it.find('option:selected').text()
      value = it.val()
      $('.' + it.attr('ref')).find('.remove-charge').trigger('click')
      Container.triggerLastTruckerChange(it)

  highlightOperationPayable: ->
    $(document).on 'mouseover', '.operation-detail', ->
      $this = $(this)
      $id = $this.attr('id')
      $('tr').removeClass('highlight')
      $('.' + $id).addClass('highlight')

    $(document).on 'mouseleave', '.operation-detail', ->
      $('tr').removeClass('highlight')

  triaxleListener: ->
    $(document).on 'change','#container_size', ->
      $this = $(this)
      $triaxle = $('#container_triaxle')
      if $this.find('option:selected').text() == '20'
        $triaxle.attr('disabled', false)
      else
        $triaxle.attr('disabled', true)
        $triaxle.attr('checked', false)

    $('#container_size').trigger('change')
  customerChange: ->
    $(document).on "change", "#container_customer_id", ->
      $this = $(this)
      pre = parseInt($this.data('pre'))
      value = $this.val()
      params = {}
      params["mark"] = "customer"
      params["id"] = value
      $.ajax(
        url: "/operation_types/options"
        type: "GET"
        data: $.param(params)
      ).done (data)->
        $this.data('pre', value)
        if confirm("Would you like to apply current charges to new customer?")
          $('.receivable-company').each ->
            $(this).val(value).trigger('change') if parseInt($(this).val()) == pre
        else
          $('.receivable-company').each ->
            $(this).closest('tr').find('.remove-charge').trigger('click') if parseInt($(this).val()) == pre

  sslineChange: ->
    $(document).on "change", "#container_ssline_id", ->
      value = $(this).val()
      params = {}
      params["mark"] = "ssline"
      params["id"] = value
      $.ajax
        url: "/operation_types/options"
        type: "GET"
        data: $.param(params)

      params["container_id"] = $('#container_id').val()
      $.ajax
        url: "/chassises/options"
        type: "GET"
        data: $.param(params)

  warningOnDeleteOperation: ->
    $(document).on "mouseover", ".quick-delete", ->
      $this = $(this)
      if $('.' + $this.attr('ref')).length > 0
        $this.attr('data-confirm', 'Warning: The related accounts payable line items highlighted in yellow above will also be removed! Are you sure that you want to continue?')
      else
        $this.attr('data-confirm', 'Warning: Are you sure that you want to continue?')

  typesOnSize: ->
    enables =
      20: ["DV", "FR", "OT", "RF", "TANK"]
      40: ["DV", "DV OT", "DV RF", "FR", "HC", "HC RF", "OT", "TANK"]
      45: ["DV", "HC"]
      53: ["DV"]
    $(document).on "change", ".container-size", ->
      $this = $(this)
      $this.addClass('inited')
      size = $this.find('option:selected').text()
      $type = $this.closest('.size-type').find('.container-type')
      $type.find('option').attr('disabled', false)
      if size != ''
        $type.find('option').attr('disabled', true)
        $(enables[size]).each (index, name)->
          $type.find('option').filter ->
            $(this).attr('disabled', false) if $(this).text()==name
        $type.val('') if $type.find('option:selected').is(':disabled')
    $('.container-size:not(.inited)').trigger('change')


Container.events()

$(document).on 'turbolinks:load', ->
  Container.init()
