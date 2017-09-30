class Accounting::TpCustomer < Accounting::TpCompany
  before_create :default_attrs

  private
  def default_attrs
    if admin&&admin.has_role?(:dispatcher)
      self.for_container = true
    end
  end
end