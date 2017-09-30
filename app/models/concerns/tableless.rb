class Tableless

  include ActiveModel::Validations
  include ActiveModel::Conversion
  extend ActiveModel::Callbacks
  extend ActiveModel::Naming

  define_model_callbacks :initialize

  def initialize(attributes={})
    (attributes||{}).each do |name, value|
      method = "#{name.to_s}=".to_sym
      send(method, value) if respond_to?(method)
    end
    run_callbacks :initialize
  end

  def persisted?
    false
  end

end