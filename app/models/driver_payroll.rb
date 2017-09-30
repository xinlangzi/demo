class DriverPayroll

  attr_accessor :driver

  def initialize(driver)
    @driver = driver
  end

  def status
    case true
    when outstanding_invoices.empty?
      :ok
    when !good_day_log?
      :alert
    when !invoices_pending_j1s.empty?
      :alert
    else
      :ok
    end
  end

  def good_day_log?
    outstanding_invoices.all?(&:good_day_log?)
  end

  def invoices_pending_j1s
    @invoices_pending_j1s||= outstanding_invoices.select(&:pending_j1s?)
  end

  def containers_pending_j1s
    invoices_pending_j1s.map do |invoice|
      invoice.containers.select do |container|
        container.pending_j1s?(driver)
      end
    end.flatten.uniq
  end

  def outstanding_invoices
    @outstanding_invoices||= DriverPayroll.outstanding_invoices.where("companies.id = ?", driver.id).select(&:ready_to_pay?)
  end

  def self.outstanding_invoices
    PayableInvoice.outstanding
                  .joins(:company)
                  .where("companies.type = ?", 'Trucker')
                  .order("companies.name ASC, invoices.issue_date ASC")
  end

end
