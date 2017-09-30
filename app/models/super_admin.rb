class SuperAdmin < Admin
  has_many :invoices

  # This overrides has_access? in user.rb to give root access to admin

  def is_superadmin?
    true
  end

  def has_access?(controller, action)
    true
  end

end
