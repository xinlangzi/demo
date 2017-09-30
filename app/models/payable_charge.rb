class PayableCharge < Charge
  validates :name, uniqueness: { scope: [:charge_id] }, unless: :hub_id
  validates :amount, presence: true, if: :preset?
  has_many :overrides, class_name: 'OverridePayableCharge', foreign_key: :charge_id, dependent: :destroy
  has_many :container_charges, ->{ where(chargable_type: 'PayableCharge') }, class_name: 'ContainerCharge', foreign_key: :chargable_id

  def parent
    nil
  end

  def payable?
    true
  end

  def self.bobtail
    find_by(name: 'Bobtail Fee')
  end

  def self.prepull
    find_by(name: 'Pre-Pull Fee')
  end

  def self.toll_surcharge
    find_by(name: 'Toll Surcharge')
  end

  def self.fuel_surcharge
    find_by(name: 'Fuel Surcharge')
  end

  def self.other
    find_by(name: 'Other')
  end

end
