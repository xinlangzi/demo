class ShipmentMailer < MailerBase

  def email(attrs)
    @shipment = Shipment.new(attrs)
    container = @shipment.container
    subject = container.kind_of?(ImportContainer) ?
                "REF #{container.reference_no}, ID #{container.id}, #{container.container_no}" :
                "REF #{container.reference_no}, ID #{container.id}, BK #{container.ssline_booking_no}"

    @shipment.files.each_with_index do |doc, index|
      attachments["#{index+1}-#{doc.file_identifier}"] = doc.file.read if doc.file_exists?
    end

    mail(
      from: sender_name_for(:order_status),
        to: @shipment.recipients,
       bcc: [SystemSetting.default.dispatch_email],
   subject: subject
    )
  end
end
