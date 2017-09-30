App.operation = App.cable.subscriptions.create "OperationChannel",
  connected: ->
    console.log "OperationChannel: connected"

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    switch data.action
      when "refresh"
        Operation.refresh(data.id)


  refresh: ->
    @perform 'refresh'
