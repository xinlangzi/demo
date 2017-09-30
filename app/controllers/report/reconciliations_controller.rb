class Report::ReconciliationsController < ApplicationController

  def search
    search_params = params[:search].permit! rescue {}
    if params[:commit] == "Search"
      @reconciliation = Report::Reconciliation.new
      @search = Payment.search(search_params)
      @reconciliation.search_params = search_params
      show
    else
      from = search_params[:cleared_date_gteq]
      to = search_params[:cleared_date_lteq]
      options = { name: "#{from}~#{to}", cleared_from: from, cleared_to: to, backend: true }
      @reconciliation = Report::Reconciliation.create(options)
      ReconciliationWorker.perform_async(@reconciliation.id)
      flash[:notice] = "Reconciliation report is running at the background!"
      redirect_to action: :index
    end
  end

  def index
    @search = Payment.search(params[:search])
    @reconciliations = Report::Reconciliation.page(params[:page])
  end

	def show
		@reconciliation||= Report::Reconciliation.find(params[:id])
    unless @reconciliation.backend?
      @by_companies = @reconciliation.by_companies
      @classify_for_containers = @reconciliation.classify_by_container_charge
      @classify_for_third_parties = @reconciliation.classify_by_third_party_category
      @classify_for_adjustments = @reconciliation.classify_by_adjustment_category
      @classify_for_credits  = @reconciliation.classify_by_credit_category
    end
	end

  def to_csv
    if params[:id].present?
      @reconciliation = Report::Reconciliation.find(params[:id])
    else
      @reconciliation = Report::Reconciliation.new
      @reconciliation.search_params = params[:search]
    end

    case params[:type]
    when 'by_category'
      data = @reconciliation.csv_by_category
      name = "Reconciliation-By-Category-#{@reconciliation.name}"
    else
    end
    send_data(data, type: 'text/csv; charset=utf-8; header=present', filename: "#{name}.csv")
  end

  def new
    @search_params = params[:search].permit! rescue {}
    @search = Payment.search(@search_params)
    @reconciliation = Report::Reconciliation.new
    @payable_payments = Payment.payables.unreconciled.search(@search_params).result
    @receivable_payments = Payment.receivables.unreconciled.search(@search_params).result
    respond_to do |format|
      format.html
      format.js
    end
  end

  def create
    @reconciliation = Report::Reconciliation.new(secure_params)
    @reconciliation.user = current_user
    @success =  @reconciliation.save
    flash[:notice] = 'Reconciliation created successfully.' if @success
  end

  def edit
    @reconciliation = Report::Reconciliation.find(params[:id])
    @reconciled_payments = @reconciliation.payments
    @payable_payments = @reconciled_payments.payables + Payment.payables.unreconciled
    @receivable_payments = @reconciled_payments.receivables + Payment.receivables.unreconciled
    @payable_amount = @reconciliation.payable_amount
    @receivable_amount = @reconciliation.receivable_amount
  end

  def update
    @reconciliation = Report::Reconciliation.find(params[:id])
    @success = @reconciliation.update_attributes(secure_params)
    flash[:notice] = 'Reconciliation updated successfully.' if @success
  end

  def destroy
    @reconciliation = Report::Reconciliation.find(params[:id])
    @success = @reconciliation.destroy
    flash[:notice] = 'Reconciliation deleted successfully.' if @success
    if @success
      redirect_to :action => 'index'
    else
      render :nothing => true
    end
  end

  def calculate_amount
    unless secure_params.blank?
      pids = secure_params[:pids]
      payable_payments = Payment.payables.where(id: pids).all
      receivable_payments = Payment.receivables.where(id: pids).all
      @payable_amount = payable_payments.map(&:amount).map(&:to_f).sum
      @receivable_amount = receivable_payments.map(&:amount).map(&:to_f).sum
    else
      @payable_amount, @receivable_amount = 0, 0
    end
  end

  private

    def secure_params
      params.require(:reconciliation).permit(:name, pids: [])
    end

end
