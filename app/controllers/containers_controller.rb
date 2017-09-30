class ContainersController < ApplicationController
  include ContainerFilters
  before_action :check_lock, only: [:edit, :update, :destroy, :toggle_task]
  before_action :deal_with_appt_time, only: [:create, :update, :update_appt_time]

  def user_id
    if params[:format] == 'xml'
      authenticate_or_request_with_http_basic do |email, password|
        session[:uid] = User.authenticate(email, password).try(:id)
      end
    else
      super
    end
  end

  def find_by_terminal(options)
    for_terminal = { terminal_id_eq: options.delete(:terminal_id_eq) }
    for_terminal.values.join('').blank? ? nil : crud_class.default.confirmed.for_user(current_user).search(for_terminal).result.pluck(:id)
  end

  def find_by_trucker(options)
    for_trucker = { trucker_id_eq: options.delete(:trucker_id_eq) }
    for_trucker.values.join('').blank? ? nil : crud_class.default.confirmed.for_user(current_user).search(for_trucker).result.pluck(:id)
  end

  def find_by_consignee(options)
    for_consignees = { consignee_name_like: options.delete(:consignee_name_like), consignee_city_like: options.delete(:consignee_city_like), consignee_state_eq: options.delete(:consignee_state_eq)}
    for_consignees.values.join('').blank? ? nil : crud_class.default.confirmed.for_user(current_user).search(for_consignees).result.pluck(:id)
  end

  def find_by_shipper(options)
    for_shippers = { shipper_name_like: options.delete(:shipper_name_like), shipper_city_like: options.delete(:shipper_city_like), shipper_state_eq: options.delete(:shipper_state_eq)}
    for_shippers.values.join('').blank? ? nil  : crud_class.default.confirmed.for_user(current_user).search(for_shippers).result.pluck(:id)
  end

  def index
    session[:per_order_stack]||= 30
    session[:container_selectors]||= []
    params[:q]||={}
    params[:q][:hub_id_in] = accessible_hubs.map(&:id)
    params[:q][:hub_id_eq]||= current_hub.try(:id)
    params[:q].permit!
    options = params[:q].to_h.clone
    ids = []
    ids << find_by_terminal(options)
    ids << find_by_trucker(options)
    ids << find_by_consignee(options)
    ids << find_by_shipper(options)
    ids.compact!
    unless ids.empty? # [[id1, id2], [id2, id3]]
      ids = ids.inject(&:&)
      options[:id_in] = ids.blank? ? [0] : ids
    end
    @q = crud_class.default.confirmed.for_user(current_user).order_stack_assocs.summary_charges.search(options)
    respond_to do |format|
      format.html {
        @containers = @q.result.order("containers.id DESC").page(params[:page]).per(session[:per_order_stack])
        @search = crud_class.search(params[:q]) # for search widget form
      }
      format.csv {
        @containers = @q.result.order("containers.id DESC").limit(1000)
        send_data(Container.to_csv(@containers, current_user), type: 'text/csv; charset=utf-8; header=present', filename: 'containers.csv')
      }
      format.xml {
        @containers = @q.result.order("containers.id DESC").limit(1000)
        render xml: Container.array_of_xml_attributes(@containers)
      }
    end
  end

  def per_order_stack
    session[:per_order_stack] = params[:per].to_i
    respond_to do |format|
      format.js
    end
  end

  def edi
    @import_containers = ImportContainer.for_user(current_user).by_edi
    @export_containers = ExportContainer.for_user(current_user).by_edi
  end

  def inquire
    @container = Container.for_user(current_user).query(params[:id]).first
    respond_to do |format|
      format.html{
        redirect_to @container if @container
      }
    end
  end

  def show
    @container = crud_class.for_user(current_user).view_assocs.find(params[:id])

    respond_to do |format|
      format.html
      # format.xml { render :xml => @container.xml_attributes.to_xml }
    end
  end

  def preview
    @container = crud_class.for_user(current_user).view_assocs.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def print
    params[:online] = true
    @container = crud_class.for_user(current_user).view_assocs.find(params[:id])
    render layout: 'print_container'
  end

  def history
    @container = crud_class.find(params[:id])
    @vid = params[:vid]
    render template: 'containers/history'
  end

  def new
    if crud_class == Container
      render template: 'containers/choose_type'
    else
      if params["#{crud_class.to_s.underscore}_id"]
        copy_forward_id = params["#{crud_class.to_s.underscore}_id"]
        container = crud_class.find(copy_forward_id)
        authorize container, :edit?
        @container = crud_class.build_similar_to(container)
      else
        type_ids = Settings.default_operations[request.fullpath]
        @container = crud_class.new(operation_type_ids: type_ids)
        @container.default_chassis_condition
        @container.customer = current_user
      end
      @container.hub||= current_hub
      @container.default_chassis_pickup_return if current_user.is_customer?
      render template: 'containers/new'
    end
  end

  def create
    @container = crud_class.new(container_params)
    @container.hub = current_hub
    respond_to do |format|
      format.js{ render template: "containers/#{params[:tmpl]}"}#tmpl: warnings
      format.html do
        @container.payable_container_charges.update_collection(container_charges_params(:payable))
        @container.receivable_container_charges.update_collection(container_charges_params(:receivable))
        if current_user.is_admin?
          @container.customer_id = container_params[:customer_id] if params.has_key?(:container)
        else
          @container.customer = current_user
        end
        begin
          @container.valid?
          @container.save_as!(params[:commit], current_user)
        rescue => ex
          render template: 'containers/new'
        else
          flash[:notice] = "Container successfully created."
          redirect_to @container
        end
      end
    end
  end

  def edit
    @container = crud_class.for_user(current_user).find(params[:id])
    @container.latest_version!
    authorize @container, :edit?
    handle_redirected_params
  end

  def update
    @container = crud_class.for_user(current_user).find(params[:id])
    authorize @container, :edit?
    @container.attributes = container_params
    respond_to do |format|
      format.js{ render template: "containers/#{params[:tmpl]}"} #tmpl: warnings
      format.html do
        begin
          Container.transaction do
            @container.payable_container_charges.update_collection(container_charges_params(:payable))
            @container.receivable_container_charges.update_collection(container_charges_params(:receivable))
            @container.save_as!(params[:commit], current_user)
          end
        rescue => ex
          @container.latest_version!
          render template: 'containers/edit'
        else
          flash[:notice] = "Container successfully updated."
          redirect_to @container
        end
      end
    end
  end

  def save_charges
    @container = crud_class.for_user(current_user).find(params[:id])
    respond_to do |format|
      format.js{
        begin
          Container.transaction do
            @container.payable_container_charges.update_collection(container_charges_params(:payable))
            @container.save!
          end
          @info = "Charges were saved successfully!"
        rescue => ex
          @info = ex.message
        end
      }
    end
  end

  def pre_alerts
    params[:q]||={}
    params[:q][:hub_id_eq]||= current_hub.try(:id)
    params[:q].permit!
    respond_to do |format|
      format.html{
        @search = Container.search(params[:q])
        @import_containers = @search.result.pre_alerts(current_user).import
        @export_containers = @search.result.pre_alerts(current_user).export
      }
      format.csv{
        @containers = crud_class.pre_alerts(current_user).search(params[:q]).result
        send_data(Container.to_prealert_csv(@containers), filename: "prealert_#{crud_class.to_s.tableize}.csv")
      }
    end
  end

  def confirm
    @container = crud_class.for_user(current_user).find(params[:id])
    begin
      @container.save_as!('Save as Confirmed', current_user)
      flash[:notice] = "Container is confirmed."
      redirect_to @container
    rescue => ex
      flash[:notice] = "Container was not confirmed because you need to enter more data."
      render template: 'containers/edit'
    end
  end

  def open
    @import_containers = ImportContainer.confirmed.open.for_user(current_user).all
    @export_containers = ExportContainer.confirmed.open.for_user(current_user).all
    respond_to do |format|
      format.html { render template: 'containers/open' }
      format.xml do
        @containers = @import_containers + @export_containers
        render :xml => Container.array_of_xml_attributes(@containers)
      end
    end
  end

  def monthly_volume
    if params[:filter]
      @filter = ContainerFilter.new(params[:filter])
      @filter.set_interval_of_time(params[:date])
    else
      @filter = ContainerFilter.new(from: 11.months.ago.beginning_of_month.to_date, to: Date.today)
    end
    @filter.customer_id = current_user.id if current_user.is_customer?
    @filter.trucker_id = current_user.id if current_user.is_trucker?
    # compute volume and draw the chart
    @containers = Container.compute_volume(@filter, 'monthly') if @filter.valid?
    respond_to do |format|
      format.html
      format.json
    end
  end

  def daily_volume
    if params[:filter]
      @filter = ContainerFilter.new(params[:filter])
      @filter.convert_to_dates
    else
      @filter = ContainerFilter.new(from: 1.week.ago.to_date, to: Date.today)
    end

    @filter.customer_id = current_user.id if current_user.is_customer?
    @filter.trucker_id = current_user.id if current_user.is_trucker?
    #calculate daily volume, then draw chart
    @containers = Container.compute_volume(@filter, 'daily') if @filter.valid?
    respond_to do |format|
      format.html
      format.json
    end
  end

  def mileages
    params[:q]||= { created_at_from: 1.months.ago.ymd, created_at_to: Date.today.ymd }
    @search = Container.search(params[:q])
    respond_to do |format|
      format.html
      format.json{
        @mileages_stats = Container.mileages_stats(params[:q])
      }
    end
  end

  def search
    params[:q]||={}
    params[:q].remove_empty.permit!
    @search = Container.for_user(current_user).search(params[:q])
    @containers = params[:q].blank? ? @search.result.order("id DESC").page(params[:page]).per(10) : @search.result
    respond_to do |format|
      format.html
    end
  end

  def cal_date
    @all_containers = Container.for_hub(current_hub).for_calendar(current_user, params[:date], params[:date])
    @containers = @all_containers["with_appointment"] || []
    @estimateds = @all_containers["estimated"] || []
    respond_to do |format|
      format.html{
        render partial: 'cal_date'
      }
    end
  end

  def calendar
    params[:date]||= Date.today.ymd
    @date = params[:date].to_date
    respond_to do |format|
      format.html do |html|
        html.none{
          @all_containers = Container.for_hub(current_hub).for_calendar(current_user, params[:date], params[:date])
          @drop_without_estimateds = @all_containers["drop_without_estimated"] || []
          @without_appt_dates = @all_containers["without_appointment"] || []
        }
        html.phone{
          @summary = Hub.for_user(current_user).inject({}) do |hash, hub|
            hash[hub] = Container.for_hub(hub).for_calendar(current_user, params[:date], params[:date])
            hash
          end
        }
      end
    end
  end

  def multi_calendar
    respond_to do |format|
      format.html{
        begin
          params[:date]||= Date.today.ymd
          @ccf = ContainerCalendarFilter.build(params)
          @ccf.analyse
          @search = crud_class.search(@ccf.to_search_params)
          @ccf.validate!
          driver_pane_data
          @all_containers = Container.for_hub(current_hub).for_calendar(current_user, @ccf.from.ymd, @ccf.to.ymd)
          @drop_without_estimateds = @all_containers["drop_without_estimated"] || []
          @without_appt_dates = @all_containers["without_appointment"] || []
        rescue => ex
          flash[:notice] = @invalid_date_range = ex.message
        end
      }
    end
  end

  def reload
    @container = crud_class.for_user(current_user).calendar_assocs.order_stack_assocs.summary_charges.find(params[:id])
    respond_to do |format|
      format.js
    end
  end

  def lock
    @container = crud_class.for_user(current_user).find(params[:id])
    @container.lock!
    ActionCable.server.broadcast "container", { action: 'refresh', id: @container.id }
    respond_to do |format|
      format.html { redirect_to @container }
      format.js { head :ok }
    end
  end

  def unlock
    @container = crud_class.for_user(current_user).find(params[:id])
    @container.unlock!
    ActionCable.server.broadcast "container", { action: 'refresh', id: @container.id }
    respond_to do |format|
      format.html { redirect_to @container }
      format.js { head :ok }
    end
  end

  def destroy
    @container = crud_class.for_user(current_user).find(params[:id])
    authorize @container, :destroy?
    if @container.destroy_by(current_user)
      flash[:notice] = "Container has been deleted."
      redirect_to :action => 'index'
    else
      flash[:notice] = "Container couldn't be deleted: "
      flash[:notice] += @container.errors.full_messages.join(' ')
      redirect_to @container
    end
  end

  def embed_appt_time
    @container = crud_class.find(params[:id])
  end

  def update_appt_time
    @container = crud_class.find(params[:id])
    @container.update_attributes(container_params)
  end

  def wild_search
    params[:wild_search].try(:permit!)
    @search = @wild_search = crud_class.for_user(current_user).search(params[:wild_search])
    @import_containers = @search.result.confirmed.import.page(params[:page])
    @export_containers = @search.result.confirmed.export.page(params[:page])
    @unconfirmed_import_containers = @search.result.unconfirmed.import.page(params[:page])
    @unconfirmed_export_containers = @search.result.unconfirmed.export.page(params[:page])

    respond_to do |format|
      format.html
      format.js
    end
  end

  def wild_to_csv
    containers = crud_class.for_user(current_user).search(params[:search]).result.order('containers.id DESC')
    respond_to do |format|
      format.csv{
        send_data(Container.to_csv(containers, current_user), filename: 'containers.csv')
      }
    end
  end

  def send_997_reject
    container = Container.find(params[:id])
    if container.reject_container
      flash[:notice] = "Successfully sent reject message to #{container.customer.to_s}"
      redirect_to edi_containers_path
    else
      flash[:notice] = "Send of reject message failed. Please check log for reason."
      redirect_to edit_container_path(container)
    end
  end

  def notify_truckers
    @container = crud_class.for_user(current_user).find(params[:id])
    @container.notify_truckers
    flash[:notice] = "The emails have been put into the outbox."
    redirect_to @container
  end

  def calculate_mileages
    @container = crud_class.for_user(current_user).find(params[:id])
    @container.recalculate_mileages
    respond_to do |format|
      format.html { redirect_to action: :show}
    end
  end

  def calculate_payables
    @container = crud_class.for_user(current_user).find(params[:id])
    authorize @container, :edit?
    response = @container.calculate_quote(current_user)
    flash[:notice] = "Could not calculate payables: #{response}" unless response.empty?
    respond_to do |format|
      format.html { redirect_to action: :show}
    end
  end

  def preview_quote
    @container = crud_class.for_user(current_user).find(params[:id])
    authorize @container, :edit?
    respond_to do |format|
      format.html{
        if request.get?
          @container.operations.map{|o| o.trucker_id = nil}
          @container.preview_quote(current_user)
        else
          @container.attributes = container_params
          if params[:commit]=~/Preview/
            @container.preview_quote(current_user)
          else
            begin
              @container.save_payable_container_charges!(container_charges_params(:payable))
            rescue => ex
              flash[:notice] = "Your preview quote could not be confirmed!"
            else
              flash[:notice] = "You have successfully confirmed the preview quote."
              redirect_to @container
            end
          end
        end
      }
    end
  end

  def map
    @container = crud_class.for_user(current_user).find(params[:id])
    @container_quote = ContainerQuote.new(@container, current_user)
    @trips = @container_quote.quotes.map(&:operation).map(&:location_sequences).inject([]) do |trips, locs|
      trips+= locs[0..-2].zip(locs[1..-1])
    end
    respond_to do |format|
      format.html{ render layout: 'map'}
      format.js
    end
  end

  def toggle_task
    @container = Container.for_user(current_user).find(params[:id])
    @checked = @container.toggle_task(params[:task_id])
  end

  private

  def check_lock
    if crud_class.for_user(current_user).find(params[:id]).lock
      render template: 'errors/unauthorized'
      return false
    end
  end

  def handle_redirected_params
    case true
    when params[:rail_bill].present?
      @container.rail_bill = true
      @container.valid?
    when params[:equipment_release].present?
      @container.equipment_release = true
      @container.valid?
    else
    end
  end

end
