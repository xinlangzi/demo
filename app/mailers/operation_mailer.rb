class OperationMailer < MailerBase

  def notify_when_operated_date_is_changed(recipient_id, operation_id, options={})
    recipient = Company.find(recipient_id)
    operation = Operation.find(operation_id)
    pdf = operation.images.pod.last
    @content = options[:content].gsub('&nbsp;', ' ')
    attachments["POD-#{Date.today}.pdf"] = open(pdf.file.url).read rescue open(pdf.file.path).read if pdf
    mail(
      from: sender_name_for(:order_status),
        to: CheckEmail.filter(recipient),
   subject: options[:subject]
    )
  end

  def notify_trucker_unassigned(operations, trucker_id)
    @owner = Owner.first
    @trucker = Trucker.find(trucker_id)
    @operations = operations
    @containers = @operations.map(&:container).uniq
    container_nos = @containers.map(&:container_no)
    subject = "#{@containers.first.class.to_s.underscore.titleize} #{container_nos.join('/')} move cancelled"
    mail(
      from: Owner.first.email_with_admin_name,
        to: CheckEmail.filter(@trucker),
   subject: subject
    )
  end

end
