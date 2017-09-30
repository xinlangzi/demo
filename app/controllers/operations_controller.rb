class OperationsController < ApplicationController

  respond_to :js

  def create
    ctype = params[:container_type].constantize
    @container = ctype.find(params[:container_id]) rescue ctype.new
    @container.attributes = container_params
    @operation = @container.operations.build(operation_type_id: params[:add_operation])
    head :ok if @operation.operation_type_id.nil?
  end

  def operate
    @operation = Operation.find(params[:id])
    authorize @operation, :edit?
    @operation.operate(params[:datetime], current_user)
    respond_to do |format|
      format.js {
        if @operation.errors.empty?
          ActionCable.server.broadcast "operation", { action: 'refresh', id: @operation.id }
          head :ok
        else
          render "operations/reload"
        end
      }
      format.json{
        if @operation.errors.empty?
          alter_status = alter_status_icon(@operation, :operated_at, true)
          render json: { message: 'The operation date/time was successfully set.', alter_status: alter_status }, status: :created
        else
          render json: { error: @operation.errors[:base].join('') }, status: :unprocessable_entity
        end
      }
    end
  end

  def appt
    @operation = Operation.find(params[:id])
    authorize @operation, :edit?
    @operation.appt = params[:datetime]
    @operation.save
    respond_to do |format|
      format.json{
        if @operation.errors.empty?
          render json: { message: 'The estimated re-pickup date/time was successfully set.' }, status: :created
        else
          render json: { error: @operation.errors[:base].join('') }, status: :unprocessable_entity
        end
      }
    end
  end

  def destroy
    @operation = Operation.find(params[:id]) rescue nil
    authorize @operation, :edit? if @operation
    @deleted = @operation.nil? || @operation.destroy
    @version = @operation.versions.last.try(:id) rescue nil
  end

  def cancel_operate
    @operation = Operation.find(params[:id])
    authorize @operation, :edit?
    @operation.cancel_operate
    respond_to do |format|
      format.js {
        if @operation.errors.empty?
          ActionCable.server.broadcast "operation", { action: 'refresh', id: @operation.id }
          head :ok
        else
          render "operations/reload"
        end
      }
    end
  end

  def reload
    @operation = Operation.find(params[:id])
  end

  def link
    @operation = Operation.find(params[:id])
    authorize @operation, :edit?
  end

  def linkable
    @containers = Container.includes([{ operations: [:container, :yard, :linker, :operation_type, :trucker, { company: :address_state}]}]).search(params[:q]).result.page(params[:page]).per(5)
    @me = Operation.find_by(id: params[:me])
  end

  def link_me
    @operation = Operation.find(params[:me])
    @target = Operation.find(params[:id])
    @operation.link_to(@target)
  end

  def unlink
    @operation = Operation.find(params[:id])
    @operation.unlink
  end

  def notify
    @operation = Operation.find(params[:id])
    @container = @operation.container
    @operation.notify
    respond_to do |format|
      format.js{
        if @operation.errors.empty?
          ActionCable.server.broadcast "operation", { action: 'refresh', id: @operation.id }
          head :ok
        else
          render "operations/reload"
        end
     }
    end
  end

end
