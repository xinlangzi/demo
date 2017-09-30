class ContainerType < ContainerAttribute
  has_many :extra_drayages, dependent: :delete_all
  has_many :free_outs, dependent: :delete_all

  alias_attribute :to_s, :name
end
