class AuthConstraint
  def self.superadmin?(request)
    uid = request.session[:uid]
    return false unless uid
    return User.find(uid).try(:is_superadmin?)
  end
end