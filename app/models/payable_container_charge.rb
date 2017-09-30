class PayableContainerCharge < ContainerCharge
  belongs_to :operation
  before_create :connect_to_operation

  def charges
    case chargable_type
    when "PayableCharge"
      self.class.charges
    when "Accounting::Category"
      Accounting::Category.cost.for_container
    else
      []
    end
  end

  def self.charges
    PayableCharge.all
  end

  def companies
    case chargable_type
    when "PayableCharge"
      [Terminal] # trucker is set from exact operation
    when "Accounting::Category"
      [Accounting::TpVendor]
    else
      []
    end
  end

  def uid
    self.new_record? ? @uid : (self.operation.uid.to_s rescue nil)
  end

  private

  def connect_to_operation
    self.operation_id = Rails.cache.read(@uid) || @uid
  end

end
