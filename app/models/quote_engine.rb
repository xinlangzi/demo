class QuoteEngine

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Naming

  attr_accessor :customer_id, :port_id, :rail_road_id, :ssline_id, :drop_pull, :transport_style, :live_load,
                :dest_address, :zip, :container_size_id, :container_type_id, :cargo_weight,
                :hazardous,
                :free_text1, :free_text2, :q_free_text1, :q_free_text2,
                :email_to, :rail_miles, :send_quote, :bcc_quote,
                :http_user_agent, :who, :comment, :private_comment

  validates :port_id,
            :rail_road_id,
            :ssline_id,
            :container_size_id,
            :container_type_id,
            :cargo_weight,
            :zip,
            :rail_miles, presence: true
	validates :customer_id, presence: true, if: Proc.new{|quote_engine| !quote_engine.who_quote.nil?}
  validates :email_to, presence: true, unless: Proc.new{|quote_engine| quote_engine.who_quote&&quote_engine.who_quote.is_admin?}
	validates :free_text1, presence: true, if: Proc.new{|quote| quote.q_free_text1.to_f > 0}
	validates :free_text2, presence: true, if: Proc.new{|quote| quote.q_free_text2.to_f > 0}
  validates :zip, presence: true
  validates :email_to, multiple_email: true

  CARGO_WEIGHTS = {
    "0" =>{
      "1" => ["under 37,500 lbs", "over 37,500 lbs to max 43,000 lbs"],
      "2" => ["up to 42,000 lbs"],
      "3" => ["up to 42,000 lbs"],
      "4" => ["up to 44,000 lbs"]
    },
    "1" => {
      "1" => ["under 35,500 lbs", "over 35,500 lbs to max 43,000 lbs"],
      "2" => ["up to 40,000 lbs"],
      "3" => ["up to 42,000 lbs"],
      "4" => ["up to 42,000 lbs"]
    }
  }


LIVE_LOAD = 1
DROP_PULL = 2
LIVE_LOAD_AND_DROP_PULL = 3


  NO_YES = [["no", 0], ["yes", 1]]

  validate do
		errors.add(:base, "Google maps returned an invalid route. Please try again.") unless valid_miles
		errors.add(:q_free_text1, "should >= 0") if !self.q_free_text1.blank?&&(Float(self.q_free_text1) < 0 rescue true)
		errors.add(:q_free_text2, "should >= 0") if !self.q_free_text2.blank?&&(Float(self.q_free_text2) < 0 rescue true)
  end

  def self.cargo_weight_options(ctype, csize)
    name = ContainerType.find_by_id(ctype).name rescue ''
    key = name.include?('RF') ? '1' : '0'
    (CARGO_WEIGHTS[key][csize]||[]) rescue []
  end

  def initialize(options={})
    options.each do |key, value|
      method = "#{key.to_s}=".to_sym
      send(method, value) if respond_to?(method)
    end
  end

  def who_quote
		User.find_by_id(self.who)
  end

  def email_to=(e)
		@email_to = e.nil? ? e : e.strip
  end

  def rail_miles=(routes)
    @rail_miles = routes.gsub(',', '').split("|").collect{|r| r=~/(\d.*\d)/; $1}.inject({}){|map_routes, r| k,v = r.split(":"); map_routes[k] = v;map_routes} rescue {}
  end

  def rail_roads
    RailRoad.where(id: @rail_road_id)
  end

  def sslines
    Ssline.where(id: @ssline_id)
  end

  def cargo_weight
    @cargo_weight.try(:reject, &:blank?)
  end

  def valid_miles
		self.rail_roads.detect{|rr|	(self.rail_miles[rr.id.to_s].to_f/METER_TO_MILE).round(2)==0}.nil?
  end

  def transport_style=(val)
    self.drop_pull = [DROP_PULL, LIVE_LOAD_AND_DROP_PULL].include?(val.to_i)
    self.live_load = [LIVE_LOAD, LIVE_LOAD_AND_DROP_PULL].include?(val.to_i)
  end

  def build(user=nil)
    begin
      user_id = user.id rescue nil
      to_send_quote(user)
      spot_quotes = []
      cargo_weight.each do |cw|
        rail_roads.to_a.product(sslines.present? ? sslines : [nil]).each do |rail_road, ssline|
          spot_quotes << SpotQuote.create!({
            rail_road_id: rail_road.id,
            ssline_id: (ssline.id rescue nil),
            meters: self.rail_miles[rail_road.id.to_s].to_f*2, #round trip
            email_to: self.email_to, customer_id: self.customer_id,
            port_id: self.port_id, dest_address: self.dest_address,
            drop_pull: self.drop_pull, live_load: self.live_load,
            container_type_id: self.container_type_id,
            container_size_id: self.container_size_id, cargo_weight: cw,
            hazardous: self.hazardous,
            free_text1: self.free_text1, free_text2: self.free_text2,
            q_free_text1: self.q_free_text1, q_free_text2: self.q_free_text2,
            comment: self.comment,
            private_comment: self.private_comment,
            user_id: user_id
          })
        end
      end

      SpotQuoteWorker.perform_async(self.to_json, spot_quotes.map(&:id)) if self.email_to&&self.bcc_quote
    rescue =>ex
      puts ex.backtrace
      Rails.logger.info(ex.backtrace)
      Rails.logger.info(ex.message)
    end
    spot_quotes
  end

  def to_send_quote(user)
    case user
    when Admin
      self.send_quote = true
      self.bcc_quote = true
    when CustomersEmployee
      regexp = /#{self.email_to}/i
      self.send_quote = regexp.match(user.customer.email).present?
      self.send_quote ||= !user.customer.employees.email_like(self.email_to).empty?
      self.bcc_quote = true
    else
      emails = self.email_to.split(/[;|,]/)
      customer = Company.match_customer(emails)
      self.send_quote = !customer.nil?
      self.customer_id = customer.id rescue nil
      self.bcc_quote = !!self.customer_id
    end
  end

  def persisted?
    false
  end

end
