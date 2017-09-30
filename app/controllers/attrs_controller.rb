class AttrsController < ApplicationController

  before_action :update_permission, only: [:update]

  def update
    begin
      array = params[:ref].split(":")
      method = array.pop
      id = array.pop
      klass = array.join(":").constantize ## Module::Class
      if current_user.is_admin?
        @object = klass.find(id)
      else
        @object = klass.for_user(current_user).find(id)
      end
      @object.save_attribute!(method, params[:val], current_user)
    rescue ActiveRecord::RecordNotFound => ex
      @error = "Request on invalid resource!"
    rescue => ex
      @error = ex.message
    end
    respond_to do |format|
      format.js
      format.json{
        unless @error
          alter_status = alter_status_icon(@object, method, true)
          render json: { message: "#{method.titleize} was saved successfully!", alter_status: alter_status }, status: :created
        else
          render json: { error: @error }, status: :unprocessable_entity
        end
      }
    end
  end

  def dups
    @duplicates = Attr.duplicates(params[:mark], params[:id], params[:term])
  end

  private
  def update_permission
    # almost update by admin, open some permission to others
    return true if current_user.is_admin?
    accessible = case params[:ref]
    when /Container:\d+:(chassis_no|container_no|seal_no|weight_decimal_humanized|chassis_pickup_at|chassis_return_at)/
      current_user.is_trucker?
    else
      false
    end
    unless accessible
      render json: { error: 'You are not authorized to process!'}, status: :unauthorized
      return false
    end
  end
end
