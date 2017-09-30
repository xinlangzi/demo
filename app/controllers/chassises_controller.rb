class ChassisesController < ApplicationController

  def options
    @container = Container.new(ssline_id: params[:id])
    @container.hub = Container.find(params[:container_id]).try(:hub) rescue current_hub
    @options = ContainerChassis.build_options(@container)
    respond_to do |format|
      format.js
    end
  end

  def charges
    params[:q]||={}
    params[:q].permit!
    eager_loads = [{ operations: :trucker }, { payable_container_charges: [:chargable, :company, { line_item: :invoice }, :operation] }]
    @chassis_nos = params[:q][:chassis_no_within].split(/\n|\,/).map(&:strip).remove_empty rescue []
    @search = Container.search(params[:q])
    @containers = params[:q].empty? ? @search.result.none : @search.result.includes(eager_loads)
  end

  def show
    @containers = Container.where(chassis_no: params[:id]).order("delivered_date DESC")
    respond_to do |format|
      format.html{ render layout: 'empty'}
    end
  end

  def audit
    if request.get?
      @records = AuditChassis.analyse(session[:chassis_csv])
    else
      session[:chassis_csv] = params[:file].read
      redirect_to action: :audit
    end
  end

  def toggle
    session[:chassis_tags]||= []
    if params[:check].to_boolean
      session[:chassis_tags] << params[:tag]
    else
      session[:chassis_tags].delete(params[:tag])
    end
    head :ok
  end

end
