class Report::AuditChargesController < Report::BasesController

  before_action :set_container, only: [:view]

  def view
    @payable_container_charges = @container.payable_container_charges.includes(:container, :chargable, :company, { operation: :trucker }, { line_item: :invoice })
    @receivable_container_charges = @container.receivable_container_charges.includes(:container, :chargable, :company, { line_item: :invoice })
    @audit_charge = AuditCharge.new(container: @container)
    respond_to do |format|
      format.html{ render layout: 'empty' }
    end
  end

  def unresolved
    @search = AuditCharge.await_to_resolve.search(params[:q])
    @audit_charges = @search.result.order("container_id ASC").includes(container: :hub)
  end

  def errors
    params[:q]||= { status_eq: AuditCharge.statuses[:await_to_resolve] }
    @search = AuditCharge.with_errors.search(params[:q])
    @audit_charges = @search.result.order("container_id ASC").includes(container: :hub)
  end

  def create
    @audit_charge = AuditCharge.new(secure_params)
    @audit_charge.save
    respond_to do |format|
      format.js
    end
  end

  def destroy
    @audit_charge = AuditCharge.find(params[:id])
    @audit_charge.destroy
    respond_to do |format|
      format.js
    end
  end


  private
    def set_container
      @container = Container.for_user(current_user).find(params[:id])
    end

    def secure_params
      params.require(:audit_charge).permit(:container_id, :assignee_id, :category, :error, :status, :comment)
    end
end
