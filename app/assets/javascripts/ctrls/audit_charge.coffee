window.AuditCharge =

  events: ->
    AuditCharge.prevNext()

  prevNext: ->
    $(document).on 'click', '.next-audit-charges', ->
      id = $(this).data('id')
      $('a:contains(' + id + ')').closest('tr').next().find('a.view-charges').trigger('mouseover').trigger('click')

    $(document).on 'click', '.prev-audit-charges', ->
      id = $(this).data('id')
      $('a:contains(' + id + ')').closest('tr').prev().find('a.view-charges').trigger('mouseover').trigger('click')

AuditCharge.events()
