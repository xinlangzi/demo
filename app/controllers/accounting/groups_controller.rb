class Accounting::GroupsController < ApplicationController

  respond_to :html

  def index
    @groups = Accounting::Group.all
  end

  def new
    @group = Accounting::Group.new
  end

  def create
    @group = Accounting::Group.new(secure_params)
    flash[:notice] = "Accounting group #{@group.name} was created successfully." if @group.save
    respond_with @group, location: accounting_groups_path
  end

  def edit
    @group = Accounting::Group.find(params[:id])
  end

  def update
    @group = Accounting::Group.find(params[:id])
    flash[:notice] = "Accounting group #{@group.name} was updated successfully." if @group.update(secure_params)
    respond_with @group, location: accounting_groups_path
  end

  def destroy
    @group = Accounting::Group.find(params[:id])
    flash[:notice] = "Accounting group #{@group.name} was deleted successfully." if @group.destroy
    respond_with(@group)
  end

  private

    def secure_params
      params.require(:group).permit(:name, :balance_sheet, :profit_loss)
    end

end
