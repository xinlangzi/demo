class ReceivableInvoice < ContainerInvoice
  include InvoiceBase::ReceivableInvoice
  paginates_per 50

  attr_accessor :status

  has_many :ehtmls, as: :ehtmlable
  has_many :line_items, class_name: 'ReceivableLineItem', foreign_key: :invoice_id, dependent: :destroy

  validates_date :issue_date
  alias_attribute :date, :issue_date

  validates :sent_to_whom, multiple_email: true, if: Proc.new{|invoice| invoice.to_email_now}
  validates :sent_to_whom, presence: true, if: Proc.new{|invoice| invoice.to_email_now}

  scope :unemailed, ->{ where(should_be_emailed: true) }

  before_update :should_be_emailed_again

  # I have the number because of the imported invoices
  after_create do
    # I create these invoices myself and I need generate my own invoice no
    update_attribute(:number, id) if number.blank?
  end

  def bill_to
    self.company
  end

  def bill_from
    Owner.first
  end

  def should_be_emailed_again
    # when an invoice is being paid, its balance changes but it shouldn't be emailed again
    # if line items are being added/removed to/from an invoice, both amount and balance will
    # change, but balance will be ignored and it'll have to be reemailed because of the new amount
    ignored_attributes = %w(should_be_emailed date_sent comments balance sent_to_whom updated_at transmission_status)
    self.should_be_emailed = date_sent.nil? || (!date_sent.nil? && !(changed - ignored_attributes).blank?)
    true
  end

  def should_it_be_emailed_again?
    should_be_emailed && date_sent
  end

  def preview_210
    Edi::Message210.new(self).construct.gsub(/~/, "~\n")
  end

  def transmit_by_edi!
    self.company.edi_provider.enqueue(210, { invoice_id: self.id })
	end

  def self.email!(id, html)
    find(id).email!(html)
  end

  def icon
    "fa fa-money green"
  end

  #a string of PDF data
  def to_pdf(html)
    pdf = CombinePDF.new
    data = Wisepdf::Writer.new.to_pdf(html, page_size: "letter", margin: { top: 5, bottom: 5, left: 5, right: 5 })
    pdf << CombinePDF.parse(data)

    docs = case invoice_j1s
    when /all_j1s/
      containers.map(&:all_docs).flatten.uniq.select(&:file_exists?)
    when /pod_j1s/
      containers.map(&:pod_docs).flatten.uniq.select(&:file_exists?)
    else
      []
    end

    docs.each do |doc|
      doc.recreate_versions! unless doc.pdf_exists?
      content = open(doc.file.pdf_url).read rescue open(doc.file.pdf_path).read rescue nil
      pdf << CombinePDF.parse(content) if content
    end
    pdf.to_pdf
  end

end
