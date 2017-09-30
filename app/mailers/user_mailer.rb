class UserMailer < MailerBase

  def request_set_password(id)
    @user = User.find(id)
    subject = @user.pwd_inited? ? 'Reset Password' : 'Password Initialization'
    mail(to: @user.email, subject: subject)
  end

end
