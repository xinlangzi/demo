class MobileMessage < ApplicationRecord

  def self.for_hub(hub)
    where(hub_id: hub.id).first_or_create
  end

end
