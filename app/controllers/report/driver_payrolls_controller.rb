class Report::DriverPayrollsController < Report::BasesController

  def index
    @invoices = DriverPayroll.outstanding_invoices.select(&:ready_to_pay?)
  end

end