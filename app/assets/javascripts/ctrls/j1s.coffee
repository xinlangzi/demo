window.J1s =

  events: ->
    J1s.prevNext()

  prevNext: ->
    $(document).on 'click', '.next-j1s', ->
      id = $(this).data('id')
      nextId = $('#docs li[data-id=' + id + ']').next().data('id')
      if nextId
        $.ajax
          url: '/docs/' + nextId + '/review'
          type: 'GET'
          data:
            nav: 'doc'

    $(document).on 'click', '.prev-j1s', ->
      id = $(this).data('id')
      prevId = $('#docs li[data-id=' + id + ']').prev().data('id')
      if prevId
        $.ajax
          url: '/docs/' + prevId + '/review'
          type: 'GET'
          data:
            nav: 'doc'


J1s.events()
