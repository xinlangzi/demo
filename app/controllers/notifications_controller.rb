class NotificationsController < ApplicationController

  before_action :set_notification, only: [:load, :reload, :update, :destroy]

  def toggle
    session[:notification_minimize] = !session[:notification_minimize]
    ActionCable.server.broadcast "notification_#{current_user.id}", { action: 'toggle', hidden: session[:notification_minimize] }
    respond_to do |format|
      format.js { head :ok }
    end
  end

  def load
    respond_to do |format|
      format.js
    end
  end

  def reload
    respond_to do |format|
      format.js
    end
  end

  def deleted
    respond_to do |format|
      format.js
    end
  end

  def update
    @notification.update(secure_params)
    head :ok
  end

  def destroy
    @notification.destroy
    head :ok
  end

  private

    def set_notification
      @notification = Notification.find(params[:id])
    end

    def secure_params
      params.require(:notification).permit(:user_id)
    end
end
