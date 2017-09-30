class Owner < Company
  mount_uploader :logo, LogoUploader

  validates :email, single_email: true
  validates :zip_code, numericality: true
  validates :web, format: { with: /\Ahttps?:\/\//, message: "has to begin with http:// or https://" }
  validate :only_one_owner , on: :create

  with_options presence: true do |c|
    c.validates :contact_person
    c.validates :phone
    c.validates :address_street
    c.validates :address_city
    c.validates :zip_code
    c.validates :address_state_id
    c.validates :email
    c.validates :name
  end

  def only_one_owner
    errors.add(:base, "There can be only one. You can have only one owner company.") if is_there_already_one?
  end

  # validation that is only an owner company in the database
  def is_there_already_one?
    self.class.count >= 1
  end

  def self.itself
    self.first
  end

  def self.valid?
    itself.try(:valid?)
  end

  # returns the hostname part of the uri stored in the web field
  # example: modalmatch.com
  def web_hostname
    web.gsub(/https?:\/\//, '')
  end

  # returns the protocol part of the uri stored in the web field
  # example:  http or https
  def web_protocol
    return $1 if( (web =~ /(https?):\/\//) == 0 )
  end


  # returns a string with like "Deepa Pandalai <dispatch@r2rintermodal.com>"
  def email_with_admin_name
    if User.authenticated_user
      "#{User.authenticated_user.name} <#{email}>"
    else
      email
    end
  end
end
