class SupportMailer < MailerBase

  def send_message(sender, message)
    @body = message
    @name = sender
    mail(to: ["jordan@51shepherd.com", "philip@51shepherd.com"], subject: "Message from #{sender}")
  end

end
