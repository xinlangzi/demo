module HubAssociation
  extend ActiveSupport::Concern

  module ClassMethods

    def belongs_to_hub(presence: true)
      belongs_to :hub

      validates :hub_id, presence: presence

      scope :for_hub, ->(hub){
        where(hub_id: hub.id)
      }
    end
  end
end