class OperationTypesController < ApplicationController

  def index
    @operation_types = OperationType.all
    @operation_emails = OperationEmail.all.includes(:set_date_operations)
  end

  def new
    @operation_type = OperationType.new
  end

  def create
    @operation_type = OperationType.new(operation_type_params)
    respond_to do |format|
      if @operation_type.save
        flash[:notice] = "#{@operation_type.name} was successfully created."
        format.html{redirect_to operation_types_path}
      else
        format.html{render action: "new"}
      end
    end
  end

  def edit
    @operation_type = OperationType.find(params[:id])
  end

  def update
    @operation_type = OperationType.find(params[:id])
    @operation_type.attributes = operation_type_params
    respond_to do |format|
      if @operation_type.save
        format.html{redirect_to operation_types_path, notice: "#{@operation_type.name} was updated successfully."}
      else
        format.html{render action: "edit"}
      end
    end
  end

  def destroy
    @operation_type = OperationType.find(params[:id])
    respond_to do |format|
      begin
        @operation_type.destroy
        flash[:notice] = "Operation type #{@operation_type.name} was deleted."
        format.html{redirect_to operation_types_path}
      rescue Exception => ex
        flash[:notice] = "You can't delete operation type #{@operation_type.name}."
        format.html{redirect_to operation_types_path}
      end
    end
  end

  def options
    @options = OperationType.build_options(current_hub, params[:mark], params[:id])
    respond_to do |format|
      format.js
    end
  end

  private

  def operation_type_params
    attrs = [
      :otype, :date_format, :delivered, :appt_confirmed, :required_docs, :use_bobtail, :traceable_by_customer,
      :email_when_remove_date, :email_when_set_date, :name, :options_from, :recipients, :container_type, :default, :seq_num,
      :returned, :set_date_email_id, :reset_date_email_id
    ]
    params.require(:operation_type).permit(attrs)
  end
end
