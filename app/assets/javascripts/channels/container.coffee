App.container = App.cable.subscriptions.create "ContainerChannel",
  connected: ->
    console.log "ContainerChannel: connected"

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    switch data.action
      when "refresh"
        ContainerCtrl.refreshOnCalendar(data.id)
        ContainerCtrl.refreshOnOrderStack(data.id)
