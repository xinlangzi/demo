class DriverQuotesController < ApplicationController

  skip_before_action :check_authentication, :check_authorization, except: [:quick]

  def quick
    @driver_quote = DriverQuote.new(secure_params)
    @quote = @driver_quote.quick
  end

  def index
    respond_to do |format|
      format.html{ head :ok }
      format.js
    end
  end

  def new
    respond_to do |format|
      format.html{ head :ok }
      format.js
    end
  end

  def create
    session[:driver_quotes]||=[]
    @driver_quote = DriverQuote.new(secure_params)
    if @driver_quote.valid?
      session[:driver_quotes].delete_if{|h| h[:key] == @driver_quote.key }
      session[:driver_quotes] << @driver_quote.to_h
    end
  end

  def mail
    params[:driver].permit!
    if params[:driver][:quotes].present?
      mail_quotes
    else
      mail_contact
    end
  end

  private

    def mail_contact
      DriverMailer.delay.contact(params[:driver])
      flash[:notice] = "We are very pleased to receive your contact information!"
    end

    def mail_quotes
      keys = params[:keys].split(',').map(&:strip)
      quotes = session[:driver_quotes].select{|h| keys.include?(h.with_indifferent_access[:key])}
      DriverMailer.delay.quotes(params[:driver], quotes)
      flash[:notice] = "Thank you for your interest in #{Rails.application.secrets.app}, your rates have been sent!"
    end

    def secure_params
      params.require(:quote).permit(:key, :hub_id, :rail_road_id, :destination, :miles)
    end

end
