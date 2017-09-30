class OrderMailer < MailerBase
  helper :containers

  PHILIP = 'philip@practicalstrategies.com,jordan@51shepherd.com'

  def notify_operations(operation)
    @owner = Owner.first
    @trucker = operation.trucker
    @container = operation.container
    oms = OperationMailSegment.new(@container)
    oms.build_linkeds
    @operations = oms.at_segment(operation).operations.reject(&:notified?)
    @operations.map(&:mark_notify)
    container_nos = @operations.map(&:container).uniq.map(&:container_no)
    subject = "#{@container.class.to_s.underscore.titleize} #{container_nos.join('/')} #{container_nos.size > 1 ? 'have' : 'has'} been assigned to you"
    mail(
      from: Owner.first.email_with_admin_name,
        to: @trucker.email,
   subject: subject
    )
  end

  def notify_contact_order_created(id)
    @owner = Owner.first
    @container = Container.find(id)
    @contact_person = @container.customers_employee
    subject = @container.kind_of?(ImportContainer) ?
                "REF #{@container.reference_no}, ID #{@container.id}, BOL #{@container.ssline_bl_no}" :
                "REF #{@container.reference_no}, ID #{@container.id}, BK #{@container.ssline_booking_no}"
    mail(
      from: sender_name_for(:order_status),
        to: CheckEmail.filter(@container.customers_employee),
   subject: subject
    )
  end

  def notify_pickup_info_confirmed(id, recipients)
    @owner = Owner.first
    @container = Container.find(id)
    @contact_person = @container.customers_employee
    subject = @container.kind_of?(ImportContainer) ?
                "REF #{@container.reference_no}, ID #{@container.id}, BOL #{@container.ssline_bl_no}" :
                "REF #{@container.reference_no}, ID #{@container.id}, BK #{@container.ssline_booking_no}"
    mail(
      from: sender_name_for(:order_status),
        to: recipients,
   subject: subject
    )
  end

  def notify_dispatch_order_created(id)
    @owner = Owner.first
    @container = Container.find(id)
    subject = @container.kind_of?(ImportContainer) ?
                "New Order ID #{@container.id} Import Container #{@container.container_no}" :
                "New Order ID #{@container.id} Export Container Booking No #{@container.ssline_booking_no}"
    mail(
      from: "New Order Created <#{SystemSetting.default.dispatch_email}>",
        to: SystemSetting.default.dispatch_email,
   subject: subject
    )
  end

  def notify_order_cancelled(id)
    @owner = Owner.first
    @container = Container.find(id)
    subject = @container.kind_of?(ImportContainer) ?
                "Order cancelled ID #{@container.id} Import Container #{@container.container_no}" :
                "Order cancelled ID #{@container.id} Export Container Booking No #{@container.ssline_booking_no}"
    mail(
      from: "#{Rails.application.secrets.app} Order Cancellation <#{SystemSetting.default.dispatch_email}>".strip,
        to: CheckEmail.filter(@container.customers_employee),
       bcc: [SystemSetting.default.dispatch_email],
   subject: subject
    )
  end

  def notify_trucker_container_updated(container_id, trucker_id, changes)
    @container = Container.find(container_id)
    @trucker = Trucker.find(trucker_id)
    @changes = changes
    @owner = Owner.first
    mail(
      from: Owner.first.email_with_admin_name,
        to: CheckEmail.filter(@trucker),
   subject: "#{@container.class.to_s.underscore.titleize} #{@container.container_no} updated"
    )
  end

  def notify_dispatch_new_edi_order(container_id)
    @container = Container.find(container_id)
    subject = @container.kind_of?(ImportContainer) ?
      "EDI Order Notification: Import Container ID #{@container.id}" :
      "EDI Order Notification: Export Container ID #{@container.id}"
    mail(
      from: Owner.first.email_with_admin_name,
        to: SystemSetting.default.dispatch_email,
   subject: subject
    )
  end

  def notify_dispatch_bad_edi_order(edi_log)
    subject = "Error creating order from EDI Message"
    @edi_log = edi_log
    mail(
      from: Owner.first.email_with_admin_name,
        to: SystemSetting.default.dispatch_email,
   subject: subject
    )
  end

  def notify_dispatch_edi_breakdown(edi_log_id, sending=false)
    @sending = sending
    subject = "Error #{sending ? 'Sending' : 'Retrieving'} EDI Message#{sending ? ': DO NOT IGNORE' : ''}"
    @edi_log_id = edi_log_id
    mail(
      from: Owner.first.email_with_admin_name,
        to: [SystemSetting.default.dispatch_email, PHILIP],
   subject: subject
    )
  end

  def notify_dispatch_edi_997_rejection_arrival(edi_log)
    subject = "EDI 997 Rejection Arrival"
    @edi_log = edi_log
    mail(
      from: Owner.first.email_with_admin_name,
        to: SystemSetting.default.dispatch_email,
   subject: subject
    )
  end

  def notify_dispatch_edi_unidentifiable_arrival(edi_log)
    subject = "Unidentifiable Message Arrived on EDI port"
    @edi_log = edi_log
    mail(
      from: Owner.first.email_with_admin_name,
        to: SystemSetting.default.dispatch_email,
   subject: subject
    )
  end

  def notify_dispatch_edi_cancel_known_order(container_id)
    @container = Container.find(container_id)
    mail(
      from: Owner.first.email_with_admin_name,
        to: SystemSetting.default.dispatch_email,
   subject: "EDI Cancellation Received for #{@container.class.name.titleize} ID #{@container.id}"
    )
  end

  def notify_dispatch_amend_known_edi_order(container_id)
    @container = Container.find(container_id)
    mail(
      from: Owner.first.email_with_admin_name,
        to: SystemSetting.default.dispatch_email,
   subject: "EDI Amendment Received for #{@container.class.name.titleize} ID #{@container.id}"
    )
  end

  def notify_dispatch_edi_cancel_unknown_order(edi_log_id, conditions)
    @edi_log = Edi::Log.find(edi_log_id)
    @conditions = conditions
    mail(
      from: Owner.first.email_with_admin_name,
        to: SystemSetting.default.dispatch_email,
   subject: "EDI Cancellation Received For Unidentifiable Container"
    )
  end

  def notify_dispatch_amend_unknown_edi_order(edi_log_id, conditions)
    @edi_log = Edi::Log.find(edi_log_id)
    @conditions = conditions
    mail(
      from: Owner.first.email_with_admin_name,
        to: SystemSetting.default.dispatch_email,
   subject: "EDI Amendment Received For Unidentifiable Container"
    )
  end

  def notify_dispatch_unexpected_997_match(edi_log_id, container_ids)
    @owner = Owner.first
    @edi_log_id = edi_log_id
    @empty = container_ids.empty?
    mail(
    from: Owner.first.email_with_admin_name,
    to: [SystemSetting.default.dispatch_email, PHILIP],
    subject: "EDI 997 message unexpectedly matches #{@empty ? 'no' : 'more than one' } 210 message"
    )
  end

  def notify_dispatch_unacknowledged_invoice(invoice_id, edi_log_id)
    @owner = Owner.first
    @edi_log_id = edi_log_id
    @invoice = ReceivableInvoice.find(invoice_id)
    mail(
      from: Owner.first.email_with_admin_name,
        to: [SystemSetting.default.dispatch_email, PHILIP],
   subject: "EDI 210 message (invoice) unacknowledged after 25 minutes!"
    )
  end

  def notify_owner_edi_invoice_failure(invoice_id)
    @invoice = ReceivableInvoice.find(invoice_id)
    mail(
      from: Owner.first.email_with_admin_name,
        to: [Role.find_by_name("Accounting").users.map(&:email).first, SystemSetting.default.invoice_statement_from, PHILIP],
   subject: "DO NOT IGNORE: An error occurred trying to send an invoice by EDI"
    )
  end

  def rail_bill(attrs)
    @rail_bill = RailBill.new(attrs)
    mail(
      from: @rail_bill.user.try(:email_with_name),
        to: @rail_bill.email,
        cc: [SystemSetting.default.dispatch_email].compact,
   subject: @rail_bill.subject
    )
  end

  def equipment_release(id)
    @equipment_release = EquipmentRelease.find(id)
    mail(
      from: @equipment_release.user.try(:email_with_name),
        to: @equipment_release.email,
        cc: [SystemSetting.default.dispatch_email].compact,
   subject: @equipment_release.subject
    )
  end

  def pod_to_customer(pod, pdf)
    @pod = pod
    @owner = Owner.first
    attachments["POD-#{Date.today}.pdf"] = open(pdf.file.url).read rescue open(pdf.file.path).read
    mail(
      from: Owner.first.email_with_admin_name,
        to: pod.email,
   subject: "Proof of Delivery"
    )
  end

  def notify_elink_to_customer(id, email)
    @container = Container.find(id)
    subject = @container.kind_of?(ImportContainer) ?
                "REF #{@container.reference_no}, ID #{@container.id}, BOL #{@container.ssline_bl_no}" :
                "REF #{@container.reference_no}, ID #{@container.id}, BK #{@container.ssline_booking_no}"
    mail(
      from: Owner.first.email_with_admin_name,
        to: email,
   subject: subject
    )
  end
end
