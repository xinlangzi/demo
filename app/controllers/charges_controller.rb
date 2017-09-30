class ChargesController < ApplicationController
  before_action :accounts_type

  def index
    @charges = crud_class.default
  end

  def show
    redirect_to action: 'index'
  end

  def new
    @charge = crud_class.new
    parent_id = params[:payable_charge_id] || params[:receivable_charge_id]
    @charge.charge_id = parent_id
  end

  def create
    @charge = crud_class.new(secure_params)
    respond_to do |format|
      format.html{
        if @charge.save
          redirect_to polymorphic_path(@charge.parent || @charge), notice: "Charge #{@charge.name} was successfully created."
        else
          flash[:notice] = 'Could not save charge.'
          render :new
        end
      }
    end
  end

  def edit
    @charge = crud_class.find(params[:id])
  end

  def update
    @charge = crud_class.find(params[:id])
    respond_to do |format|
     if @charge.update(secure_params)
      format.html { redirect_to polymorphic_path(@charge.parent || @charge), notice: "Charge #{@charge.name} was successfully updated." }
      format.xml  { head :ok }
     else
      format.html { render :edit }
      format.xml  { render :xml => @charges.errors, :status => :unprocessable_entity }
     end
    end
  end

  def destroy
    @charge = crud_class.find(params[:id])
    @charge.destroy
    respond_to do |format|
      format.html { redirect_to polymorphic_path(@charge.parent || @charge), notice: "Charge #{@charge.name} was successfully deleted."}
      format.xml  { head :ok }
    end
  end

  private
    def accounts_type
      @accounts_type = self.class.to_s.gsub('ChargesController', '').gsub(/Override/, '')
    end

    def secure_params
      attrs = [
        :hub_id, :charge_id, :name, :amount, :percentage, :comments, :accounting_group_id, :preset
      ]
      params.require(:charge).permit(attrs)
    end

end