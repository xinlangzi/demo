class CreditsController < ApplicationController

  before_action :set_credit, only: [:update, :destroy]

  def index
    @search = crud_class.for_user(current_user).search(params[:q])
    @credits = @search.result.order("id DESC").page(params[:page])
  end

  def new
    @credit = crud_class.new
    @credit.invoice_id = params[:invoice_id]
    @credit.issue_date = Date.today
    @credit.amount = 0
    @credit.save(validate: false)
  end

  def update
    @success = @credit.update(credit_params)
    @invoice = @credit.invoice
  end

  def destroy
    @success = @credit.destroy
    @invoice = @credit.invoice
    respond_to do |format|
      format.html{
        if @success
          redirect_to polymorphic_path(crud_class), notice: "#{crud_class.to_s.titleize} was deleted successfully."
        else
          redirect_to polymorphic_path(crud_class), notice: @credit.errors.full_messages_for(:base).join(" ")
        end
      }
      format.js
    end
  end

  private

  def set_credit
    @credit = crud_class.for_user(current_user).find(params[:id])
  end

  def credit_params
    attrs = [
      :amount, :catalogable_type_with_id, :issue_date
    ]
    params.require(:credit).permit(attrs)
  end

end