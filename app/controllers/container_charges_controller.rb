class ContainerChargesController < ApplicationController

  def new
    @container_charge = crud_class.new(uid: params[:uid])
    @container_charge.chargable_id = params[:chargable_id] # add bobtail
    @container_charge.chargable_type = params[:chargable_type]
    @container_charge.company = Company.find(params[:company_id]) unless params[:company_id].blank?
    respond_to do |format|
      format.js
    end
  end

  def changed
    params[:container]||= {}
    @container_charge = crud_class.new
    type = params[:type].gsub(/_.*/, '')
    @container_charge.attributes = container_charges_params(type)[params[:key]]
    params[:container].delete("operations_attributes") #important!!!
    @container_charge.container = Container.new(container_params)
    @container_charge.container.hub = current_hub
    @container_charge.set_default_fields
    respond_to do |format|
      format.js
    end
  end

  def index
    container_id = params[:import_container_id] || params[:export_container_id]
    @container = Container.find(container_id)
    assocs = [:operation, :chargable, :line_item, :company]

    if crud_class == ReceivableContainerCharge
      assocs.delete(:operation)
      @container_charges = @customer.present? ?
        @container.receivable_container_charges.charges(@customer.id).includes(assocs) :
        @container.receivable_container_charges.includes(assocs)
    elsif crud_class == PayableContainerCharge
      @container_charges = @trucker.present? ?
        @container.payable_container_charges.charges(@trucker.id).includes(assocs) :
        @container.payable_container_charges.includes(assocs)
    else
      raise 'Receivable or Payable charges / Hacking much?'
    end

    respond_to do |format|
      format.html{ render layout: 'empty'}
    end
  end
end
