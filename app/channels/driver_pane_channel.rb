# Be sure to restart your server when you modify this file. Action Cable runs in a loop that does not support auto reloading.
class DriverPaneChannel < ApplicationCable::Channel
  # delegate :current_user, to: :connection
  #   # dont allow the clients to call those methods
  # protected :current_user

  def subscribed
    stream_from "driver_pane"
  end

  def unsubscribed
    # Any cleanup needed when channel is unsubscribed
  end

  def dragging(data)
    ActionCable.server.broadcast "driver_pane", data
  end

  def dragged(data)
    ActionCable.server.broadcast "driver_pane", data
  end
end
