class MyMailer < MailerBase

  def send_drivers_email(params)
    file = params[:attachment]
    emails = CheckEmail.filter(params[:truckers].collect{|id| Trucker.find(id)})
    @message = params[:message]
    attachments[file.original_filename] = file.read if file
    mail(subject: params[:subject], bcc: emails)
  end

  def send_customers_email(params)
    file = params[:attachment]
    customers = CheckEmail.filter(collect_all_customer_emails(params[:customers]))
    @message = params[:message]
    attachments[file.original_filename] = file.read  if file
    mail(subject: params[:subject], bcc: customers)
  end

  def mail_spot_quotes(json, ids)
    @quote_engine = QuoteEngine.new(JSON.parse(json))
    @spot_quotes = SpotQuote.where(id: ids)
    mail(
      from: SystemSetting.default.quote_email_from,
      to: (@quote_engine.send_quote ? @quote_engine.email_to : nil),
      bcc: [SystemSetting.default.quote_bcc_to],
      subject: "Quote: #{@quote_engine.dest_address}"
    )
  end

  def invalid_address(id)
    @company = Company.find(id)
    mail(to: SystemSetting.default.incomplete_address_email_to, subject: "Non-standard address")
  end

  def forward_sms_to_email(params)
    # https://www.twilio.com/docs/api/twiml/sms/twilio_request
    @trucker = Trucker.all.detect{|t| t.pure_mobile_phone == params[:From] }
    @message = params[:Body]
    @medias  = params[:NumMedia].to_i
    @medias.times do |i|
      mime_type = params["MediaContentType#{i}".to_sym]
      blob = MyTwilio.get_media(params["MediaUrl#{i}".to_sym]) rescue nil
      attachments["media#{i+1}"] = { mime_type: mime_type, content: blob } if blob
    end
    mail(
      to: SystemSetting.default.dispatch_email,
      subject: "SMS from #{params[:From]}" + (@trucker ? " (#{@trucker.name})" : "")
    )
  end

  def mobile_apps(id)
    @owner = Owner.first
    @trucker = Trucker.find(id)
    mail(
      to: @trucker.email,
      subject: "Mobile App for Driver"
    )
  end

  private
    def collect_all_customer_emails(customer_ids)
      customer_ids.collect{|id|
        cust = Customer.find(id)
        [cust.employees.active, cust]
      }.flatten
    end
end
