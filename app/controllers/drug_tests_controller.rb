class DrugTestsController < ApplicationController
  before_action :get_trucker

  def get_trucker
    @trucker = Trucker.find(params[:trucker_id]) if params[:trucker_id]
  end

  def index
    @drug_tests = DrugTest.all
  end

  def show
    @drug_test = DrugTest.find(params[:id])
  end

  def new
    @drug_test = DrugTest.new
  end

  def edit
    @drug_test = DrugTest.find(params[:id])
  end

  def create
    @drug_test = DrugTest.new(secure_params)
    @drug_test.trucker = @trucker
    respond_to do |format|
      format.html do
        if @drug_test.save
          flash[:notice] = 'Drug test was successfully created.'
          redirect_to @trucker
        else
          render :action => :new
        end
      end
    end
  end

  def update
    @drug_test = DrugTest.find(params[:id])

    respond_to do |format|
      if @drug_test.update_attributes(secure_params)
        flash[:notice] = 'Drug test was successfully updated.'
        format.html { redirect_to @trucker }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy
    @drug_test = DrugTest.find(params[:id])
    @drug_test.destroy
    respond_to do |format|
      format.html { redirect_to @trucker }
    end
  end

  private
    def secure_params
      params.require(:drug_test).permit(:date, :test_type, :comments, :passed)
    end
end
