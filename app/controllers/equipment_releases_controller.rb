class EquipmentReleasesController < ApplicationController

  before_action :set_container, only: [:new, :build]

  def new
    authorize @container, :edit?
    @container.equipment_release = true
    init_equipment_release if @container.valid?
  end

  def build
    authorize @container, :edit?
    @container.attributes = container_params
    @container.equipment_release = true
    begin
      Container.transaction do
        @container.payable_container_charges.update_collection(container_charges_params(:payable))
        @container.receivable_container_charges.update_collection(container_charges_params(:receivable))
        @container.save!
        init_equipment_release
        @info = "Container was saved successfully. You can compose to email equipment release!"
      end
    rescue =>ex
    end
  end

  def create
    @equipment_release = EquipmentRelease.new(secure_params)
    @equipment_release.user = current_user
    @success = @equipment_release.save
    respond_to do |format|
      format.js
    end
  end

  private
    def set_container
      @container = ExportContainer.view_assocs.find(params[:container_id])
    end

    def init_equipment_release
      @equipment_release = EquipmentRelease.build(@container)
      @equipment_release.user = current_user
    end

    def secure_params
      attrs = [
        :subject, :content, :container_id, email: []
      ]
      params.require(:equipment_release).permit(attrs)
    end

end
