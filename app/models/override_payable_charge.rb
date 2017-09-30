class OverridePayableCharge < PayableCharge
  include HubAssociation
  belongs_to_hub presence: true
  belongs_to :parent, class_name: 'PayableCharge', foreign_key: :charge_id

  validates :charge_id, presence: true
  validates :hub_id, uniqueness: { scope: [:charge_id], message: "limit one custom charge per charge type per hub" }

  def name
    parent.name
  end

end
