class RailRoad < ApplicationRecord
  belongs_to :port
  has_many :spot_quotes, dependent: :nullify
  has_many :extra_drayages, dependent: :delete_all

  validates :name, presence: true
  validates :lon, presence: true,numericality: true
  validates :lan, presence: true,numericality: true
  validates :weight_rank2_fee, numericality: true
  validates :name, uniqueness: { scope: :port_id }
  validates :chassis_dray, numericality: { greater_than_or_equal_to: 0 }, allow_nil: true

  alias_attribute :to_s, :name

  def lan_lon
    [self.lan, self.lon]
  end

  def name_with_lan_lon
    "(#{lan}, #{lon}) #{name}"
  end

  def self.latest_updated
    RailRoad.order('updated_at DESC').first
  end
end
