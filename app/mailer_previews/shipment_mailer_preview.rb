class ShipmentMailerPreview < ActionMailer::Preview

  def email_for_import
    shipment = Shipment.init(ImportContainer.drop_pull.delivered.last)
    shipment.file_ids = Image.last(2).map(&:id)
    shipment.request_pickup_no = true
    shipment.request_last_free_day = true
    shipment.comment =<<-EOT.gsub(/^\s+/, '')
      Please note that these options *are not thread-safe*.
      In a multi-threaded environment they should only be set once at boot-time and never mutated at runtime.
    EOT
    ShipmentMailer.email(shipment.to_h)
  end

  def email_for_export
    shipment = Shipment.init(ExportContainer.drop_pull.delivered.last)
    shipment.comment =<<-EOT.gsub(/^\s+/, '')
      Please note that these options *are not thread-safe*.
      In a multi-threaded environment they should only be set once at boot-time and never mutated at runtime.
    EOT
    shipment.location_id = Location.where.not(address: nil).last.try(:id)
    ShipmentMailer.email(shipment.to_h)
  end

end
