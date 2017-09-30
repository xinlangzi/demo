class Report::ContainersController < Report::BasesController

  def order_creation
    @total_count = 0
    @search = Container.for_user(current_user).search(params[:search])
    if params[:search]
      @total_count = @search.result.count
      @import_confirmed = @search.result.confirmed.import
      @export_confirmed = @search.result.confirmed.export
      @import_unconfirmed = @search.result.unconfirmed.import
      @export_unconfirmed = @search.result.unconfirmed.export
      @pending_receivables = @search.result.pending_receivables
    end
    respond_to do |format|
      format.html
      format.js{
        @label = params[:label]
        @containers = instance_variable_get("@#{@label}").page(params[:page]) if @label
      }
    end
  end

  def dwelling_perdiem
    @search = Container.for_user(current_user).outgated_status.search
    @containers = @search.result.page(params[:page]).per(50)
  end

  def drops_awaiting_pick_up
    respond_to do |format|
      format.html{
        @imports = ImportContainer.for_user(current_user).drops_awaiting_pick_up
        @exports = ExportContainer.for_user(current_user).drops_awaiting_pick_up
      }
      format.csv{
        @containers = Container.for_user(current_user).drops_awaiting_pick_up
        send_data(Container.to_drops_awaiting_pickup_csv(@containers), filename: "drops-awaiting-pickup-#{Date.today.ymd}.csv")
      }
    end
  end

  def pending_empties
    params[:q]||= { hub_id_eq: current_hub.id }
    params[:q].permit!
    @search = ImportContainer.live_load.for_user(current_user).search(params[:q])
    respond_to do |format|
      format.html{
        @containers = @search.result.pending_empty.page(params[:page]).includes(:customer)
      }
      format.csv{
        @containers = @search.result.pending_empty.includes(:customer)
        send_data(Container.to_pending_empty_csv(@containers), filename: "pending-empties-#{Date.today.ymd}.csv")
      }
    end
  end

  def pending_loads
    params[:q]||= { hub_id_eq: current_hub.id }
    params[:q].permit!
    @search = ExportContainer.live_load.for_user(current_user).search(params[:q])
    respond_to do |format|
      format.html{
        @containers = @search.result.pending_load.page(params[:page]).includes(:customer)
      }
      format.csv{
        @containers = @search.result.pending_load.includes(:customer)
        send_data(Container.to_pending_load_csv(@containers), filename: "pending-loads-#{Date.today.ymd}.csv")
      }
    end
  end

  def operations_without_mark_delivery
    @containers = Container.for_user(current_user).operations_without_mark_delivery
  end

  def confirmed_without_appt_date
    @containers = Container.for_user(current_user).confirmed.without_appt_date
  end

  def pending_tasks
    @search = Container.includes([:task_comments]).confirmed.delivered.pending_tasks(params[:pending_task_ids]).search
    @containers = @search.result.page(params[:page])
  end

  def pending_receivables
    @search = Container.for_user(current_user).pending_receivables.search
    @containers = @search.result.page(params[:page])
  end

  def chassis_invoices
    q = (params[:q]||{}).remove_empty
    @filter_by_trucker = true if q[:last_trucker_id_eq].present? || q[:chassis_loss_by_eq] == "trucker"
    @search = Container.for_user(current_user).chassis_invoices.search(q)
    @containers = q.blank? ? @search.result.none : @search.result
    @containers = @containers.reject{|container| container.chassis_days.to_i > -2 } if @filter_by_trucker
  end

  def audit_charges
    q = (params[:q]||{}).remove_empty
    q[:operated_at_to]||= Date.today.beginning_of_week
    @search = Container.for_user(current_user).unlocked.search(q) # search by operated date
    ids = q.blank? ? @search.result.none.pluck(:id) : @search.result.pluck(:id)
    ids = Container.all_operated.where(id: ids).pluck(:id)
    @containers = Container.summary_charges.where(id: ids).includes(:audit_charges, :hub)
    @pending_task_ids = @containers.pending_tasks.pluck(:id)
  end

end
