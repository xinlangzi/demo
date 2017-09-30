class Crawler < User

  def xml_attributes
    owner = Owner.itself
    attributes = Hash.new

    attributes.merge!({"name" => owner.name,
           "remote_username" => self.username,
           "remote_password" => self.password,
           "remote_web" => self.web,
           "phone" => owner.phone,
           "address_street" => owner.address_street,
           "address_city" => owner.address_city,
           "address_state" => owner.address_state.abbrev,
           "zip_code" => owner.zip_code})
     return attributes
  end
end
