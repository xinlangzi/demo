class SystemLogsController < ApplicationController
  def index
    @system_logs = SystemLog.page(params[:page])
  end
end
