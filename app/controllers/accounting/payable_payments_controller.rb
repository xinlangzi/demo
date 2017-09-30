class Accounting::PayablePaymentsController < Accounting::PaymentsController

  def print
    @payment = Accounting::PayablePayment.find(params[:id])
    @check_details = @payment.get_check_details(secure_print_params[:owner])
    respond_to do |format|
      format.pdf do
        data = Wisepdf::Writer.new.to_pdf(render_to_string(
          inline: CheckTemplate.default.rtf, type: :slim),
          page_size: "letter",
          margin: { top: 0, bottom: 0, left: 0, right: 0 }
        )
        send_data(data, filename: "check-#{@payment.id}.pdf", type: :pdf)
      end
    end
  end

  def edit_number
    @payment = Accounting::PayablePayment.find(params[:id])
  end

  def update_number
    @payment = Accounting::PayablePayment.find(params[:id])
    @payment.attributes = secure_check_params
    respond_to do |format|
      format.html {
        if @payment.valid? && secure_check_params[:edit_number] == "1"
          @payment.save!
          redirect_to @payment, notice: "Check number has been saved."
        else
          render action: "edit_number"
        end
      }
    end
  end

  private

    def secure_print_params
      params.require(:accounting_payable_payment).permit(
        owner: [:address_street, :address_street_2, :address_city, :address_state_id, :zip_code]
      )
    end

    def secure_check_params
      params.require(:accounting_payable_payment).permit(:number, :edit_number)
    end
end