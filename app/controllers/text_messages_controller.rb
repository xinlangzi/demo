class TextMessagesController < ApplicationController

  def index
    @text_messages = TextMessage.page(params[:page])
  end

  def new
    @text_message = TextMessage.new(secure_params)
    @operation = Operation.find(params[:operation_id])
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @text_message = TextMessage.new(secure_params)
    @operation = Operation.find(params[:operation_id])
    respond_to do |format|
      if @text_message.save
        format.html do
          flash[:notice] = 'Text message was successfully created.'
          redirect_to(@text_message)
        end
        format.js
        format.json{ render json: { location: polymorphic_path(@operation.container, signed_at: Time.now.to_i) }, status: :created }
      else
        format.html { render :new }
        format.js { render :new }
        format.json{ render json: @text_message.errors.full_messages, status: :unprocessable_entity }
      end
    end
  end

  private

    def secure_params
      attrs = [:company_id, :container_id, :message, :phone_number, :trucker_id, :status]
      params.require(:text_message).permit(attrs)
    end

end
