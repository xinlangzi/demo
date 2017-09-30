class OperationEmailsController < ApplicationController

  respond_to :html

  def new
    @operation_email = OperationEmail.new
  end

  def edit
    @operation_email = OperationEmail.find(params[:id])
  end

  def create
    @operation_email = OperationEmail.new(secure_params)
    respond_to do |format|
      if @operation_email.save
        format.html { redirect_to operation_types_path}
      else
        format.html { render action: 'new'}
      end
    end
  end

  def update
    @operation_email = OperationEmail.find(params[:id])
    respond_to do |format|
      if @operation_email.update(secure_params)
        format.html { redirect_to operation_types_path}
      else
        format.html { render action: 'edit'}
      end
    end
  end

  def destroy
    @operation_email = OperationEmail.find(params[:id])
    @operation_email.destroy
    respond_to do |format|
      format.html { redirect_to operation_types_path}
    end
  end

  def preview
    @operation_email = OperationEmail.find(params[:id])
    @operation = @operation_email.set_date_operations.first.operations.operated.last
    respond_to do |format|
      format.html { render layout: 'mail' }
    end
  end

  private

    def secure_params
      params.require(:operation_email).permit(:name, :subject, :status_title, :content)
    end
end