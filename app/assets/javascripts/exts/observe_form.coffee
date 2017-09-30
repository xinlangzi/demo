$.fn.extend
  observeForm: ->
    $this = $(this)
    $this.off "change"
    $this.bind 'change', (event)->
      ajaxSubmit(event) unless $(event.target).hasClass('unobservable')

    ajaxSubmit = (event)->
      type = $this.data('method') || $this.attr('method') || 'GET'
      url  = $this.data('url') || $this.attr('action')
      data = $this.serializeArray()
      data.push({ name: 'changed', value: event.target.id })
      $this.find('input[type=submit]').each ->
        data.push({name: $(this).attr('name'), value: $(this).val()})
      $.ajax
        url: url
        type: type
        dataType: 'script'
        data: data

  removeThenChangeForm: ->
    $this = $(this)
    $form = $this.closest('form')
    $this.remove()
    $form.trigger('change')
