class OperationMailerPreview < ActionMailer::Preview

  def notify_when_operated_date_is_changed
    container = ImportContainer.delivered.last
    recipient = container.customers_employee
    operation = container.operations.detect{|o| o.send(:operation_email) }
    operation_email = operation.send(:operation_email)

    subject = operation_email.build_email_subject(recipient, operation)
    content = operation_email.build_email_content(recipient, operation)
    OperationMailer.notify_when_operated_date_is_changed(recipient.id, operation.id, { subject: subject, content: content })
  end

  def notify_trucker_unassigned
    container = ImportContainer.delivered.last
    operations = container.operations.reject(&:final?)
    trucker = Trucker.active.all.sample
    OperationMailer.notify_trucker_unassigned(operations, trucker)
  end
end
