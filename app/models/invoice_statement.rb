class InvoiceStatement
  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :subject, :from, :to, :bcc, :body, :customer_id, :data

  validates :subject, :to, :body, :customer_id, presence: true

  def initialize(attributes = {})
    attributes.each{ |name, value| send("#{name}=", value) }
    self.from = SystemSetting.default.invoice_statement_from
    self.bcc = SystemSetting.default.invoice_statement_bcc
  end

  def self.init(customer)
    system_setting = SystemSetting.default
    new({
      customer_id: customer.id,
      subject: "#{Date.today.us_date}, #{customer.name} #{system_setting.invoice_statement_subject}",
      body: system_setting.invoice_statement_body,
      to: customer.collection_email
    })
  end

  def customer
    Company.find(customer_id)
  end

  def email
    InvoiceMailer.delay.send_statement(self)
  end

  def persisted?
    false
  end

end