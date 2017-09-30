# require 'twilio-ruby'
class MessagingController < ApplicationController
  def index
  end

  def send_driver_text
    return if request.get?
    begin
      raise "Please select at least one trucker" if params[:truckers].to_a.empty?
      raise "Please enter text message" if params[:message].blank?
      @text_messages = Trucker.send_smses(params[:truckers], params[:message])
      @bad = @text_messages.detect { |t| t.status != "Sent" }
    rescue => ex
      @error = ex.message
    end
    respond_to do |format|
      format.js
    end
  end

  def send_driver_email
    return if request.get?
    begin
      raise "Please select at least one trucker" if params[:truckers].to_a.empty?
      raise "Please enter text message" if params[:message].blank?
      MyMailer.send_drivers_email(params).deliver_now
      respond_to do |format|
        format.html {
          redirect_to action: :send_driver_email
        }
      end
    rescue => ex
      flash[:notice] = ex.message
      respond_to do |format|
        format.html {
          render action: :send_driver_email
        }
      end
    end

  end

  def send_customer_email
    return if request.get?
    begin
      raise "Please select at least one customers" if params[:customers].to_a.empty?
      raise "Please enter text message" if params[:message].blank?
      MyMailer.send_customers_email(params).deliver_now
      respond_to do |format|
        format.html {
          redirect_to action: :send_customer_email
        }
      end
    rescue => ex
      flash[:notice] = ex.message
      respond_to do |format|
        format.html {
          render action: :send_customer_email
        }
      end
    end
  end

  def send_mobile_message
    @mobile_message = MobileMessage.for_hub(current_hub)
    return if request.get?
    @mobile_message.update(secure_mobile_message)
    respond_to do |format|
      format.html{
        flash[:notice] = 'Mobile message was updated successfully!'
        redirect_to action: :send_mobile_message
      }
    end
  end

  def forward_sms_to_email
    params.permit!
    MyMailer.delay.forward_sms_to_email(params)
    twiml = Twilio::TwiML::MessagingResponse.new
    twiml.message do |message|
      message.body('Your SMS has been forwarded by email to a dispatcher.')
    end
    render xml: twiml.to_s
  end

  private
  def secure_mobile_message
    params.require(:mobile_message).permit(:content)
  end
end
