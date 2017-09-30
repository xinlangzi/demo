class RailBillsController < ApplicationController

  before_action :set_container

  def new
    @container.rail_bill = true
    init_rail_bill if @container.valid?
  end

  def build
    @container.attributes = container_params
    @container.rail_bill = true
    begin
      Container.transaction do
        @container.payable_container_charges.update_collection(container_charges_params(:payable))
        @container.receivable_container_charges.update_collection(container_charges_params(:receivable))
        @container.save!
        init_rail_bill
        @info = "Container was saved successfully. You can compose to email rail bill!"
      end
    rescue =>ex
    end
  end

  def create
    @rail_bill = RailBill.new(secure_params)
    @rail_bill.container_id = @container.id
    @rail_bill.user_id = current_user.id
    @log = @rail_bill.save if @rail_bill.valid?
    respond_to do |format|
      format.js
    end
  end


  private
    def set_container
      @container = ExportContainer.view_assocs.find(params[:container_id])
    end

    def init_rail_bill
      @rail_bill = RailBill.build(@container)
      @rail_bill.user_id = current_user.id
    end

    def secure_params
      attrs = [
        :subject, :content, email: []
      ]
      params.require(:rail_bill).permit(attrs)
    end
end