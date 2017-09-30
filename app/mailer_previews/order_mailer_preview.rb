class OrderMailerPreview < ActionMailer::Preview

  def notify_operations
    @operation = Operation.where.not(trucker_id: nil).where(pos: 1).last
    @operation.container.operations.update_all(recipient_id: nil)
    @operation.trucker.update_column(:email, 'tueusut@gmail.com')
    OrderMailer.notify_operations(@operation)
  end

  def notify_import_created
    @container = ImportContainer.drops_awaiting_pick_up.last
    OrderMailer.notify_contact_order_created(@container.id)
  end

  def notify_export_created
    @container = ExportContainer.find(57520)
    OrderMailer.notify_contact_order_created(@container.id)
  end

  def notify_pickup_info_confirmed
    @container = ImportContainer.confirmed.last
    OrderMailer.notify_pickup_info_confirmed(@container.id, 'john@test.com')
  end

  def notify_dispatch_order_created
    @container = ExportContainer.last
    OrderMailer.notify_dispatch_order_created(@container.id)
  end

  def notify_order_cancelled
    @container = ExportContainer.last
    OrderMailer.notify_order_cancelled(@container.id)
  end

  def notify_trucker_container_updated
    @container = ExportContainer.last
    @trucker = Trucker.active.first
    OrderMailer.notify_trucker_container_updated(@container.id, @trucker.id, { 'Container No.'=> ['ZSDF234234', 'ZSDF234344']})
  end

  def notify_dispatch_new_edi_order
    @container = ImportContainer.last
    OrderMailer.notify_dispatch_new_edi_order(@container.id)
  end

  def notify_dispatch_bad_edi_order
    @container = ImportContainer.last
    OrderMailer.notify_dispatch_bad_edi_order(@container.id)
  end

  def notify_dispatch_edi_breakdown
    @container = ImportContainer.last
    OrderMailer.notify_dispatch_edi_breakdown(@container.id)
  end

  def notify_dispatch_edi_997_rejection_arrival
    @edi_log = Edi::Log.last
    OrderMailer.notify_dispatch_edi_997_rejection_arrival(@edi_log)
  end

  def notify_dispatch_edi_unidentifiable_arrival
    @edi_log = Edi::Log.last
    OrderMailer.notify_dispatch_edi_unidentifiable_arrival(@edi_log)
  end

  def notify_dispatch_edi_cancel_known_order
    @container = ImportContainer.last
    OrderMailer.notify_dispatch_edi_cancel_known_order(@container.id)
  end

  def notify_dispatch_amend_known_edi_order
    @container = ImportContainer.last
    OrderMailer.notify_dispatch_amend_known_edi_order(@container)
  end

  def notify_dispatch_edi_cancel_unknown_order
    @edi_log = Edi::Log.last
    @container = ImportContainer.last
    condition = {
      container_no: @container.container_no
    }
    OrderMailer.notify_dispatch_edi_cancel_unknown_order(@edi_log, condition)
  end

  def notify_dispatch_amend_unknown_edi_order
    @edi_log = Edi::Log.last
    @container = ImportContainer.last
    condition = {
      container_no: @container.container_no
    }
    OrderMailer.notify_dispatch_amend_unknown_edi_order(@edi_log, condition)
  end

  def notify_dispatch_unexpected_997_match
    @edi_log = Edi::Log.last
    @container = ImportContainer.last
    OrderMailer.notify_dispatch_unexpected_997_match(@edi_log, [@container.id])
  end

  def notify_dispatch_unacknowledged_invoice
    @edi_log = Edi::Log.last
    @invoice = @edi_log.customer.receivable_invoices.last
    OrderMailer.notify_dispatch_unacknowledged_invoice(@invoice.id, @edi_log.id)
  end

  def rail_bill
    @container = ImportContainer.last
    attrs = {
      container_id: @container.id,
      subject: "Send invoice out",
      email: 'demo@test.com',
      content: "Sorry to send again to remind you",
      user_id: Admin.active.first.id
    }
    OrderMailer.rail_bill(attrs)
  end

  def equipment_release
    @eq = EquipmentRelease.last
    OrderMailer.equipment_release(@eq.id)
  end

  def pod_to_customer
    pod = Pod.last
    pdf = pod.container.operations.first.images.build
    pdf.pod = true
    pdf.name = "POD"
    pdf.user = pod.user
    pdf.file = File.open(Rails.root.join('spec/fixtures/attach.png'))
    pdf.save!
    OrderMailer.pod_to_customer(pod, pdf)
  end

  def notify_elink_to_customer
    OrderMailer.notify_elink_to_customer(Container.last.id, 'john@test.com')
  end

end
