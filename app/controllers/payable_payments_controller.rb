class PayablePaymentsController < PaymentsController

  def print
    @payment = PayablePayment.find(params[:id])
    @check_details = @payment.get_check_details(secure_print_params[:owner])
    respond_to do |format|
      format.pdf {
        disposition = params[:disposition] || 'attachment'
        data = Wisepdf::Writer.new.to_pdf(
          render_to_string(inline: CheckTemplate.default.rtf, type: :slim),
          page_size: "letter",
          margin: { top: 0, bottom: 0, left: 0, right: 0 }
        )
        send_data(data, filename: "check-#{@payment.id}.pdf", type: :pdf)
      }
    end
  end

  def edit_number
    @payment = PayablePayment.find(params[:id])
  end

  def update_number
    @payment = PayablePayment.find(params[:id])
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

  def  onfile1099
    if params[:q]
      params[:q].permit!
      params[:q][:company_onfile1099_eq] = true
      @search = Payment.payables.search(params[:q])
      @payments = @search.result.order("companies.name ASC").includes(company: [:address_state, :billing_state])
    else
      @search = Payment.payables.search
    end
    respond_to do |format|
      format.html
      format.csv{
        send_data(Payment.onfile1099_to_csv(@payments), filename: "Onfile1099-Payments.csv")
      }
    end

  end

  private

    def secure_print_params
      params.require(:payable_payment).permit(
        owner: [:address_street, :address_street_2, :address_city, :address_state_id, :zip_code]
      )
    end

    def secure_check_params
      params.require(:payable_payment).permit(:number, :edit_number)
    end
end
