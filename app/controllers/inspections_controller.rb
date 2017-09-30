class InspectionsController < ApplicationController
  before_action :set_inspection, only: [:show, :edit, :update, :destroy, :invoiced, :uninvoiced]

  # GET /inspections
  # GET /inspections.json
  def index
    default_params
    @search = Inspection.search(params[:q])
    @summary = @search.result.summary
    @trucker = Trucker.find_by(id: params[:trucker_id])
    respond_to do |format|
      format.html{
        if @trucker
          @inspections = @search.result.where(trucker_id: @trucker.id).includes(:trucker, :adjustments)
          @operations = @trucker.operations
                                .search(actual_appt_gteq: @from, actual_appt_lteq: @to)
                                .result.order("actual_appt DESC")
                                .includes(container: :customer)
        else
          @inspections = @search.result.page(params[:page]).includes(:trucker, :adjustments)
        end
      }
      format.csv{
        @inspections = @search.result
        send_data(Inspection.to_csv(@inspections), filename: "inspections-#{Date.today.ymd}.csv")
      }
    end
  end

  def show
    render layout: false
  end

  def detail
    params[:q] = { trucker_id_eq: current_user.id, year: Date.today.year}
    @search = Inspection.search(params[:q])
    @inspections = @search.result
  end

  # GET /inspections/new
  def new
    @inspection = Inspection.new
  end

  # GET /inspections/1/edit
  def edit
  end

  # POST /inspections
  # POST /inspections.json
  def create
    @inspection = Inspection.new(secure_params)

    respond_to do |format|
      if @inspection.save
        format.html { redirect_to inspections_path, notice: "Inspection for #{@inspection.trucker} on #{@inspection.issue_date} was successfully created." }
        format.json { render :show, status: :created, location: @inspection }
      else
        format.html { render :new }
        format.json { render json: @inspection.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /inspections/1
  # PATCH/PUT /inspections/1.json
  def update
    respond_to do |format|
      if @inspection.update(secure_params)
        format.html { redirect_to inspections_path, notice: "Inspection for #{@inspection.trucker} on #{@inspection.issue_date} was successfully updated." }
        format.json { render :show, status: :ok, location: @inspection }
      else
        format.html { render :edit }
        format.json { render json: @inspection.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /inspections/1
  # DELETE /inspections/1.json
  def destroy
    respond_to do |format|
      format.html {
        if @inspection.destroy
          flash[:notice] = "Inspection for #{@inspection.trucker} on #{@inspection.issue_date} was successfully deleted."
        else
          flash[:notice] = @inspection.errors.full_messages_for(:base).join(" ")
        end
        redirect_to inspections_path
      }
    end
  end

  def invoiced
    if request.get?
      @adjustment = @inspection.build_adjustment
    else
      @adjustment = @inspection.adjustments.find(params[:adjustment_id])
      @success = @adjustment.update(adjustment_params)
    end
  end

  def uninvoiced
    @adjustment = @inspection.adjustments.find(params[:adjustment_id])
    @adjustment.destroy
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_inspection
      @inspection = Inspection.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def secure_params
      params.require(:inspection).permit(
        :trucker_id, :issue_date, :amount, :point, :level,
        violations_attributes: [
          :id, :code, :unit, :oos, :description, :included_in_sms, :basic, :reason_not_included_in_sms, :_destroy
        ]
      )
    end

    def adjustment_params
      params.require(:adjustment).permit(:invoice_id, :amount, :comment)
    end

    def default_params
      params[:q]||={}
      params[:q].permit!
      params[:q][:issue_date_gteq]||= Date.today.beginning_of_year
      params[:q][:issue_date_lteq]||= Date.today.end_of_year
      @from = params[:q][:issue_date_gteq]
      @to = params[:q][:issue_date_lteq]
    end

end
