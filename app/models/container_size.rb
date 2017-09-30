class ContainerSize < ContainerAttribute
  has_many :extra_drayages, dependent: :delete_all
  has_many :free_outs, dependent: :delete_all
  has_many :spot_quotes, dependent: :delete_all
  has_many :containers, dependent: :nullify

  alias_attribute :to_s, :name

  SIZES_TYPES = {
    '20' => ["DV", "FR", "OT", "RF", "TANK"],
    '40' => ["DV", "DV OT", "DV RF", "FR", "HC", "HC RF", "OT", "TANK"],
    '45' => ["DV", "HC"],
    '53' => ["DV"]
  }

  def self.option_with_type
    SIZES_TYPES.map do |size, types|
      container_size = ContainerSize.find_by_name(size)
      types.map do |type|
        container_type = ContainerType.find_by_name(type)
        ["#{container_size.name} #{container_type.name}", "#{container_size.id}:#{container_type.id}"] rescue nil
      end.compact
    end.flatten(1)
  end

end
