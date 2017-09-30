window.PendingDoc =

  events: ->
    PendingDoc.chooseDoc()
    PendingDoc.chooseAction()
    PendingDoc.clickZoomContainer()

#### EVENT BEGIN ####
  chooseDoc: ->
    $(document).on 'click', '#pending-docs li', ->
      $(this).toggleClass('active')

  chooseAction: ->
    $(document).on 'click', '.choose-action', ->
      ids = []
      $('#pending-docs li.active').each ->
        ids.push $(this).data('id')
      unless ids.length > 0
        alert("Please choose at least one doc to assign")
      else
        $.ajax
          url: '/docs/assign'
          type: "PUT"
          data:
            image:
              imagable_type: $(this).data('imagable-type')
              imagable_id: $(this).data('imagable-id')
              column_name: $(this).data('column-name')
            ids: ids

  clickZoomContainer: ->
    $(document).on 'click', '.zoomContainer', ->
      PendingDoc.focusOnTagsInput()

  focusOnTagsInput: ->
    $('div.tagsinput input').focus()
#### EVENT END ####

PendingDoc.events()
