class Mobiles::StatusesController < ApplicationController

  def index
    @statuses = Mobile::Status.all
  end

  def destroy
    @status = Mobile::Status.find(params[:id])
    @status.destroy
    redirect_to action: :index
  end

end
