class ReceivableCharge < Charge
  validates :name, uniqueness: { scope: [:charge_id] }, unless: :hub_id
  has_many :overrides, class_name: 'OverrideReceivableCharge', foreign_key: :charge_id, dependent: :destroy
  has_many :container_charges, ->{ where(chargable_type: 'ReceivableCharge') }, class_name: 'ContainerCharge', foreign_key: :chargable_id

  def parent
    nil
  end

  def receivable?
    true
  end

  def self.rate_incl_fuel_surcharge
    like_name('%rate%fuel surcharge%').first
  end

  def self.triaxle_fee
    like_name('%triaxle fee%').first
  end

  def self.chassis_fee
    like_name('%chassis fee%').first
  end

  def self.lift_fee
    like_name('%lift fee%').first
  end

  def self.other
    like_name('other').first
  end

  def self.drop_charges
    like_name('%drop charges%').first
  end

  def self.chassis_dray
    like_name('%chassis dray%').first
  end

  def self.like_name(name)
    where("lower(name) LIKE ?", name)
  end

end
