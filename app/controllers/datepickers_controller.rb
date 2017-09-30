class DatepickersController < ApplicationController

  def update
    @object = Datepicker.set_date(params)
    @method = params[:method]
    respond_to do |format|
      format.js
      format.json{
        if @object.errors.empty?
          alter_status = alter_status_icon(@object, @method, true)
          render json: { message: 'The date/time was successfully set.', alter_status: alter_status }, status: :created
        else
          render json: { error: @object.errors[:base].join('') }, status: :unprocessable_entity
        end
      }
    end
  end

  def destroy
    @object = Datepicker.reset_date(params)
    @method = params[:method]
    respond_to do |format|
      format.js
    end
  end

end