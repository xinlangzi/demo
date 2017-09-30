class ReceivablePayment < ContainerPayment
  validates :number, presence: true
  validates :number, uniqueness: { scope: [:company_id], case_sensitive: false }

  alias_attribute :date, :issue_date

end
