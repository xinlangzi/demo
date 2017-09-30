window.AuditChassis =

  init: ->
    $('#audit-chassises').DataTable
      paging: false
      searching: true
      bSort: false
      dom: 'Bfrtp'
      buttons: [
        'copyHtml5'
        'csvHtml5'
      ]

  events: ->
    AuditChassis.toggleSelect()

  toggleSelect: ->
    $(document).on 'change', 'input.audit-row', ->
      App.markSelection($(this))
      $.ajax
        url: '/chassises/toggle'
        type: 'GET'
        data:
          tag: $(this).data('id')
          check: $(this).is(':checked')


AuditChassis.events()

$(document).on 'turbolinks:load', ->
  AuditChassis.init()