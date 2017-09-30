class ApplicantMailer < MailerBase

  def notify_hr(id)
    @owner = Owner.first
    @applicant = Applicant.find(id)
    mail(
      from: Owner.first.email,
        to: SystemSetting.default.driver_hr_email,
   subject: "New Driver Application"
    )
  end

  def invite(id)
    @applicant = Applicant.find(id)
    @trucker = @applicant.trucker
    emails = [@applicant.email, @trucker.email].uniq
    mail(
      from: Owner.first.email,
        to: emails,
   subject: "Fullfill Driver Application"
    )
  end
end
