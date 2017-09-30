class SpotQuote < ApplicationRecord
  paginates_per 20
  belongs_to :hub
  belongs_to :rail_road
  belongs_to :customer
  belongs_to :ssline
  belongs_to :user
  belongs_to :container_size
  belongs_to :container_type
  belongs_to :container
  has_one :overwritten, class_name: 'SpotQuote', foreign_key: :original_id
  belongs_to :original, class_name: 'SpotQuote', foreign_key: :original_id
  attr_accessor :start_address, :meters, :operation_id, :tolls, :tolls_fee, :toll_surcharge,
                :triaxle, :add_rail, :for_trucker, :preset

  validates :email_to, multiple_email: true
  validates :miles, numericality: { greater_than: 0 }, unless: :original_id
  validates :expired_date, presence: true, if: :original_id
  validates :base_rate_fee, :drop_rate_fee, :reefer_fee,
            :fuel_amount, :q_free_text1, :q_free_text2,
            :over1, :over2, :reefer_fee,
            :chassis_fee, :chassis_dray,
            numericality: true, allow_blank: true

  scope :to_review, ->{ where("expired_date > ?", Date.today) }
  scope :quoted, ->{ where(original_id: nil) }
  scope :triaxle_weight, ->{ where("container_size_id = 1 AND cargo_weight = 2") }
  scope :legal_weight, ->{ where("cargo_weight != 2") }
  scope :expired_instant, ->{ where("instant_date < ?", Date.today) }

  scope :created_gteq, ->(date){
    where("created_at >= ?", (date.in_time_zone rescue nil))
  }

  scope :created_lt, ->(date){
    where("created_at < ?", (date.in_time_zone + 1 rescue nil))
  }

  default_scope { order("id DESC") }

  TOLLS_KEYWORD = "tolls"
  RAIL_ROAD_ADDITIONAL_KEYWORD = "additional"

  after_initialize :init_hub
  before_create :set_base_rate_fee,
                :customer_fuel_amount,
                :set_drop_rate,
                :set_reefer_fee,
                :set_over1,
                :set_over2,
                :set_chassis_fee,
                :set_chassis_dray,
                :set_expiration_date, unless: :original_id

  after_save :overriding, if: :original_id


  def self.ransackable_scopes(auth=nil)
    [
      :created_gteq,
      :created_lt
    ]
  end

  def fine_print
    prints = []
    prints << FinePrint.unsure_of_ssl_chassis if ssline_id.nil?&&!is_triaxle?&&live_load?
    prints << FinePrint.two_day_accrual_drop if two_day_accrual_drop?
    prints << FinePrint.three_day_accrual_drop if three_day_accrual_drop?
    prints << FinePrint.additional_drayage(self.ssline, self.rail_road) if extra_drayage?
    prints.compact.join(' ')
  end



  def triaxle=(value)
    @triaxle = value.is_a?(String) ? (value=='0' ? false : true) : value
  end

  def container
    operation.container rescue nil
  end

  def operation
    Operation.find(self.operation_id) rescue nil
  end

  def csize
    self.container_size.name rescue nil
  end

  def ctype
    self.container_type.name rescue nil
  end

  def cweight
    key = is_reefer? ? '1' : '0'
    (self.container_size_id.nil?||self.cargo_weight.nil?) ? 'Please Select' : QuoteEngine::CARGO_WEIGHTS[key][self.container_size_id.to_s][self.cargo_weight-1]
  end

  def is_reefer?
    ctype.to_s.include?('RF')
  end

  def reefer_info
    is_reefer? ? QuoteEngine::NO_YES[1][0] : QuoteEngine::NO_YES[0][0]
  end

  def hazardous_info
    self.hazardous ? QuoteEngine::NO_YES[1][0] : QuoteEngine::NO_YES[0][0]
  end

  def increase_rate
    self.for_trucker ? increase_trucker : increase_customer
  end

  def increase_trucker
    1 + (self.operation.trucker.latest_discount.amount/100.0 rescue 0.0)
  end

  def increase_customer
    1 + (self.customer.latest_discount.amount/100.0 rescue 0.0)
  end

  def increase_rate_all
    self.for_trucker ? rate_all_truckers : rate_all_customers
  end

  def rate_all_truckers
    1 + (Discount.rate_for_all_truckers.amount rescue 0.0)/100.0
  end

  def rate_all_customers
    1 + (Discount.rate_for_all_customers.amount rescue 0.0)/100.0
  end

  def combined_increases
    increase_rate*increase_rate_all
  end

  def adjust_fee(fee, adjust=true)
    fee+=30 if adjust&&self.dest_address =~/WI|MN/ rescue 0
    fee
  end

  def set_base_rate_fee(adjust=true)
    klass = self.for_trucker ? DriverRate : CustomerRate
    before, after = klass.interpolate(hub, miles.to_f)
    avg = (after.rate - before.rate)/(after.miles - before.miles) rescue 0
    fee = (before.rate + avg*(miles - before.miles)).round(2) rescue 0
    self.base_rate_fee = (adjust_fee(fee, adjust)*combined_increases).round(2)
  end

  def customer_fuel_amount(ppg=nil)
    ppg = Fuel.latest_price(hub) # price per gallon
    before, after = CustomerRate.interpolate(hub, miles.to_f)
    avg = (after.actual_fuel_amount - before.actual_fuel_amount)/(after.miles - before.miles)
    avg = [0, avg].max
    fee = (before.actual_fuel_amount + avg*(miles - before.miles)).round(2)
    fee+= miles/MileRate.default(hub).triaxle*ppg - miles/MileRate.default(hub).regular*ppg if is_triaxle?
    self.gallon_price = ppg
    self.fuel_amount = fee.round(2)
  end

  def driver_fuel_amount(ppg=nil)
    ppg = Fuel.latest_price(hub) # price per gallon
    mpg = self.is_triaxle? ? MileRate.default(hub).triaxle : MileRate.default(hub).regular # miles per gallon
    before, after = DriverRate.interpolate(hub, miles.to_f)
    bfee = before.miles/mpg*(ppg - 2.0) rescue 0
    afee = after.miles/mpg*(ppg - 2.0) rescue 0
    bfee = [0, bfee].max
    afee = [0, afee].max
    avg = (afee - bfee)/(after.miles - before.miles) rescue 0
    self.fuel_amount = ((bfee + avg*(miles - before.miles))*rate_all_truckers).round(2) rescue 0
  end

  def driver_toll_surcharge
    percentage = toll_surcharge_for_hub.try(:percentage).to_f/100.0
    self.toll_surcharge = (base_rate_fee * percentage).round(2)
  end

  def set_drop_rate
    self.drop_rate_fee = self.drop_pull ? CustomerDropRate.interpolate(hub, miles.to_f).first.value_at(self.base_rate_fee + self.fuel_amount) : 0
  end

  def set_reefer_fee
    self.reefer_fee = is_reefer? ? 40 : 0
  end

  def set_over1
    self.over1 = is_triaxle? ? (self.miles < 65 ? 90 : (self.miles > 100 ? 130 : 110)) : 0.0
  end

  def set_over2
    self.over2 = is_triaxle? ? self.rail_road.weight_rank2_fee.to_f  : 0.0
  end

  def set_chassis_fee
    self.chassis_fee = is_triaxle? ? 0 : (self.ssline.chassis_fee.to_f rescue 0)
  end

  def set_chassis_dray
    self.chassis_dray = is_triaxle? ? 0 : (self.rail_road.chassis_dray.to_f rescue 0)
  end

  def set_expiration_date
    self.expired_date = 6.months.since.to_date unless original_id
  end

  def overriding
    original.instant_date = nil
    original.expired_date = self.expired_date
    original.overrided_at = Time.now
    original.save
  end

  def two_day_accrual_drop?
    drop_pull&&(chassis_fee > 0) || drop_pull&&!is_triaxle?&&ssline_id.nil?
  end

  def three_day_accrual_drop?
    drop_pull&&is_triaxle?
  end

  def extra_drayage?
    conditions = { ssline_id: self.ssline_id, container_size_id: self.container_size_id, container_type_id: self.container_type_id }
    !rail_road.extra_drayages.where(conditions).empty?
  end

  def is_triaxle?
    (self.container_size_id == 1)&&(self.cargo_weight == 2) || self.triaxle
  end

  def percent_fuel
    (self.fuel_amount/self.base_rate_fee*100.0).round(2)
  end

  def cal_total
    self.base_rate_fee  + self.fuel_amount + self.tolls_fee + self.toll_surcharge
  end

  def total
    [self.base_rate_fee, self.fuel_amount, self.drop_rate_fee, self.chassis_fee, self.chassis_dray, self.over1, self.over2, self.reefer_fee, self.q_free_text1, self.q_free_text2].map(&:to_f).sum.round(2)
  end

  def total_without_drop_pull
    (total - self.drop_rate_fee.to_f).round(2)
  end

  def meters=(v)
     self.miles = (v.to_f/METER_TO_MILE).round(2)
  end

  def save_charge
    ret = {}
    return ret if operation.nil?
    trucker = operation.trucker
    if operation.container.require_prepull_charge?
      ret[:info] = ret[:error] = "Container requires prepull charge"
      ret[:charges] = operation.container.reload.payable_container_charges.size
    elsif trucker.nil?
      ret[:info] = ret[:error] = "No trucker is assigned"
      ret[:charges] = operation.container.reload.payable_container_charges.size
    # elsif operation.invoiced?
    #   #shall we update?
    #   ret[:info] = ret[:error] = "Already invoiced"
    #   ret[:charges] = operation.container.reload.payable_container_charges.size
    elsif check_existing_payable_container_charges(operation)
      ret[:info] = ret[:error] = "Conflicting category already posted"
      ret[:charges] = operation.container.reload.payable_container_charges.size
    else
      begin
        exist_auto_saved = operation.payable_container_charges.auto_saved
        ret[:removed] = exist_auto_saved.size
        exist_auto_saved.destroy_all
        self.hub = operation.container.hub
        old_count = operation.container.reload.payable_container_charges.size
        base_rate_charge
        fuel_surcharge_charge
        tolls_fee_charge
        toll_surcharge_charge
      rescue =>ex
        ret[:error] = ex.message
      end
      ret[:charges] = operation.container.reload.payable_container_charges.size
      ret[:saved] = ret[:charges] - old_count
      ret[:info] = "#{ret[:removed]} removed, #{ret[:saved]} added; #{ret[:error]}"
    end
    ret
  end

  def base_rate_charge
    operation.container.payable_container_charges.create!(base_rate_charge_attrs) if self.base_rate_fee.to_f > 0
  end

  def base_rate_charge_attrs
    {
      auto_save: true,
      amount: self.base_rate_fee.to_f,
      chargable_type: 'PayableCharge',
      chargable_id: PayableCharge.find_by_name(self.fuel_amount.to_f > 0 ? "Base Rate" : "Rate Incl. of Fuel Surcharge").try(:id),
      company_id: operation.trucker_id,
      uid: operation.id,
      details: "#{self.miles.precision2}miles"
    }
  end

  def fuel_surcharge_charge
    operation.container.payable_container_charges.create!(fuel_surcharge_charge_attrs) if self.fuel_amount.to_f > 0
  end

  def fuel_surcharge_charge_attrs
    {
      auto_save: true,
      amount: self.fuel_amount.to_f,
      chargable_type: 'PayableCharge',
      chargable_id: PayableCharge.fuel_surcharge.try(:id),
      company_id: operation.trucker_id,
      uid: operation.id,
      details: "#{self.percent_fuel.precision2}% $#{self.gallon_price.precision2}"
    }
  end

  def tolls_fee_charge
    operation.container.payable_container_charges.create!(tolls_fee_charge_attrs) if self.tolls_fee.to_f > 0
  end

  def tolls_fee_charge_attrs
    {
      auto_save: true,
      amount: self.tolls_fee.to_f,
      chargable_type: 'PayableCharge',
      chargable_id: PayableCharge.other.try(:id),
      company_id: operation.trucker_id,
      uid: operation.id,
      details: "#{TOLLS_KEYWORD}"
    }
  end

  def toll_surcharge_for_hub
    PayableCharge.toll_surcharge.by_hub(hub)
  end

  def toll_surcharge_charge
    operation.container.payable_container_charges.create!(toll_surcharge_charge_attrs) if self.toll_surcharge.to_f > 0
  end

  def toll_surcharge_charge_attrs
    {
      auto_save: true,
      amount: self.toll_surcharge.to_f,
      chargable_type: 'PayableCharge',
      chargable_id: PayableCharge.toll_surcharge.try(:id),
      company_id: operation.trucker_id,
      uid: operation.id,
      details: "#{toll_surcharge_for_hub.try(:percentage).to_f}% of Base Rate"
    }
  end

  def check_existing_payable_container_charges(operation)
    base_rate_ids = PayableCharge.where(name: Container::UNIQ_CHARGES_PER_CONTAINER).pluck(:id)
    chargable_ids = operation.payable_container_charges.pluck(:chargable_id)
    (chargable_ids&base_rate_ids).present?
  end

  def overrided?
    overwritten.present?
  end

  def override
    return overwritten if overwritten
    overwritten = self.dup
    overwritten.original_id = self.id
    overwritten
  end

  def is_instant?
    instant_date == Date.today
  end

  def save_as_receivables(container, commit=true)
    method = commit ? :create : :build
    attrs = {company_id: container.customer_id, auto_save: true}
    container.receivable_container_charges.auto_saved.destroy_all if commit
    rate_incl_fuel = [base_rate_fee, fuel_amount, reefer_fee, q_free_text1, q_free_text2].map(&:to_f).sum.round(2)
    container.receivable_container_charges.send(method, attrs.merge(chargable_type: 'ReceivableCharge', chargable_id: ReceivableCharge.rate_incl_fuel_surcharge.try(:id), amount: rate_incl_fuel)) rescue nil
    container.receivable_container_charges.send(method, attrs.merge(chargable_type: 'ReceivableCharge', chargable_id: ReceivableCharge.drop_charges.try(:id), amount: drop_rate_fee)) if !container.live_load?&&drop_rate_fee > 0 rescue nil
    container.receivable_container_charges.send(method, attrs.merge(chargable_type: 'ReceivableCharge', chargable_id: ReceivableCharge.triaxle_fee.try(:id), amount: over1)) if over1 > 0 rescue nil
    container.receivable_container_charges.send(method, attrs.merge(chargable_type: 'ReceivableCharge', chargable_id: ReceivableCharge.lift_fee.try(:id), amount: over2)) if over2 > 0 rescue nil
    container.receivable_container_charges.send(method, attrs.merge(chargable_type: 'ReceivableCharge', chargable_id: ReceivableCharge.chassis_fee.try(:id), amount: chassis_fee)) if chassis_fee > 0 rescue nil
    container.receivable_container_charges.send(method, attrs.merge(chargable_type: 'ReceivableCharge', chargable_id: ReceivableCharge.chassis_dray.try(:id), amount: chassis_dray)) if chassis_dray > 0 rescue nil
  end

  private

    def init_hub
      self.hub = rail_road.try(:port).try(:hub) if rail_road
    end
end
