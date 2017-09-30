class ApplicantMailerPreview < ActionMailer::Preview
  def notify_hr
    ApplicantMailer.notify_hr(Applicant.first.id)
  end

  def invite
    applicant = Applicant.where.not(token: nil).first
    applicant.invite
    ApplicantMailer.invite(applicant.id)
  end
end