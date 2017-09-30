class SupportController < ApplicationController
  def new
    render :template => 'support/new'
  end

  def create
    begin
      name = params["sender"]
      message = params["message"]
      raise "Please enter your name" if name.blank?
      raise "Please enter message" if message.blank?
      SupportMailer.send_message(name, message).deliver_now
      flash[:notice] = "Thank you. We will support you as soon as possible."
      redirect_to :action => 'new'
    rescue Exception => ex
      flash[:notice] = ex.message
      render :action => 'new'
    end
  end
end
