App.driver_pane = App.cable.subscriptions.create "DriverPaneChannel",
  connected: ->
    console.log "DriverPaneChannel: connected"
    # Called when the subscription is ready for use on the server

  disconnected: ->
    # Called when the subscription has been terminated by the server

  received: (data) ->
    # Called when there's incoming data on the websocket for this channel
    switch data.action
      when "dragging"
        date = data.date
        driver_id = data.driver_id
        selector = "#dddrivers[data-date='" + date + "'] div[data-li='" + driver_id + "']"
        $(selector).addClass('locked')
      when "dragged"
        date = data.date
        driver_id = data.driver_id
        selector = "#dddrivers[data-date='" + date + "'] div[data-li='" + driver_id + "']"
        $(selector).removeClass('locked')
      when "reload"
        DriverPane.load(data.date)

  dragging: (date, driver_id)->
    @perform 'dragging', date: date, driver_id: driver_id

  dragged: (date, driver_id)->
    @perform 'dragged', date: date, driver_id: driver_id
