class UserMailerPreview < ActionMailer::Preview

  def reset_password
    UserMailer.request_set_password(Admin.active.first.id)
  end

  def init_password
    user = Applicant.first.company
    user.update_column(:encrypted_password, nil)
    user.reload.hire_now
    UserMailer.request_set_password(user.id)
  end

end