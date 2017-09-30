window.ContainerTask =

  current: null

  init: ->
    ContainerTask.build()

  events: ->
    ContainerTask.onClick()

  build: ->
    $('.check-tasks').each ->
      ids = $(this).data('ids')
      disabled = $(this).data('disabled') == 1
      $(this).find('input').each ->
        $input = $(this)
        $input.attr('disabled', disabled)
        unless $.inArray(parseInt($input.val()), ids) < 0
          $input.attr('checked', 'checked')

  closeFacebox: (checked)->
    $(document).trigger('close.facebox')
    ContainerTask.reloadCurrent(checked)

  reloadCurrent: (checked)->
    ContainerTask.current.prop('checked', checked)
    ContainerTask.current = null

##### Events #######
  onClick: ->
    $(document).on 'click', '.check-tasks input', (event)->
      $input = $(this)
      cid = $input.closest('.check-tasks').data('id')
      tid = $input.val()
      ContainerTask.current = $input
      if $input.is(":checked")
        event.preventDefault()
        $('<a>').attr('href', "/task_comments/popup?container_id=" + cid + "&container_task_id=" + tid).attr('ref', 'eventY').facebox().trigger('click')
        $('#facebox').css('top', event.pageY - 20)
      else
        $.ajax
          url: '/containers/' + cid + '/toggle_task?task_id=' + tid
          type: 'GET'

ContainerTask.events()

$(document).on 'turbolinks:load', ->
  ContainerTask.init()

$(document).on 'ajaxStop', ->
  ContainerTask.build()