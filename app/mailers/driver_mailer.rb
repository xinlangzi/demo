class DriverMailer < MailerBase

  def contact(driver)
    @owner = Owner.first
    @driver = driver.with_indifferent_access
    mail(
      from: Owner.first.email,
       bcc: [SystemSetting.default.driver_quote_bcc_to],
   subject: "New Driver Contact Information"
    )
  end

  def quotes(driver, quotes)
    @owner = Owner.first
    @driver = driver.with_indifferent_access
    @driver_quotes = quotes.map{|q| DriverQuote.new(q) }
    mail(
      from: SystemSetting.default.dispatch_email,
        to: @driver[:email],
       bcc: [SystemSetting.default.driver_quote_bcc_to],
   subject: "Owner Operator Rate Inquiry from #{@owner.name}"
    )
  end
end