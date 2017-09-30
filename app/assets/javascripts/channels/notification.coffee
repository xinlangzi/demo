App.container = App.cable.subscriptions.create "NotificationChannel",
  connected: ->
    console.log "NotificationChannel: connected"

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    switch data.action
      when "create"
        Notification.on_create(data.id)
      when "update"
        Notification.on_update(data.id)
      when "destroy"
        Notification.on_destroy(data.id)
      when "toggle"
        Notification.on_toggle(data.hidden)
