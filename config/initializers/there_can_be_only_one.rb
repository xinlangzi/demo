# enforces that only one object will be saved in the database for this model
ActiveRecord::Base.class_eval do
  def self.there_can_be_only_one
    validate :singleness_check, :on => :create
    define_method :singleness_check do
      errors.add(:base, "There can be only one.") if self.class.count >= 1 && new_record?
    end
  end

  def self.number_to_currency(number, options={})
    ActionController::Base.helpers.number_to_currency(number, options)
  end
end
