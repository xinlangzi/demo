class Ssline < Company
  has_many :depots, ->{ order('companies.name ASC') }
  has_many :containers, ->{ order('containers.created_at DESC') }
  has_many :import_containers, ->{ order('containers.created_at DESC') }
  has_many :export_containers, ->{ order('containers.created_at DESC') }
  has_many :extra_drayages, dependent: :delete_all
  has_many :free_outs, dependent: :delete_all
  accepts_nested_attributes_for :free_outs, reject_if: lambda { |a| a[:days].blank? }, allow_destroy: true

  validates :email , multiple_email: true
  validates :free_outs, nested_attributes_uniqueness: { scope: [:container_size_id, :container_type_id, :ssline_id]}
  validates :name, uniqueness: { scope: [:deleted_at] }

  with_options multiple_email: true do |company|
    company.validates :rail_billing_email
    company.validates :eq_team_email
  end

  scope :group_options, ->{ order('name ASC') }
  scope :has_chassis_fee, ->{ where("chassis_fee > 0").order('name') }
  default_scope { where("name NOT LIKE ? ", "ZZZ%") }

  before_destroy do
    throw :abort unless self.containers.blank?
  end

  def is_ssline?
    true
  end

  def email_valid?(method)
    addresses = send(method).to_s.split(/,|;/)
    addresses.present?&&addresses.all?{|address| EMAIL_REGEX.match(address.strip) }
  end

end
