class Api::Container
  def self.filter(params)
    if params[:type] == "import" and params[:status] == "undepoted"
      ImportContainer.no_pending_receivables.undepoted.includes(:ssline, {operations: { company: :address_state } }, :container_size, :container_type, :hub ).map do |container|
        next unless container.ssline.edi_customer_code.present? # when edi_customer_code is required for SSLine, can remove this line
        next if ExportContainer.where(container_no: container.container_no).where("created_at BETWEEN ? AND ?", container.created_at, container.created_at + 30.days).count > 0
        consignee = container.consignees_or_shippers_info.first
        terminal = container.terminals_info.first
        next if terminal.try(:name) =~ /DO NOT USE/
        next unless terminal.rail_road.present?
        {
          container_id: container.id,
          container_no: container.container_no,
          chassis_no: container.chassis_no,
          size: container.container_size.name,
          type: container.container_type.name,
          ssline: container.ssline.edi_customer_code,
          terminal: terminal.name,
          eta: container.terminal_eta,
          appt_date: container.appt_date,
          appt_time: container.appt_start,
          consignee_address: consignee.city_state_zip,
          consignee_latitude: consignee.lat.to_f,
          consignee_longitude: consignee.lng.to_f,
          chassis_type: container.triaxle ? "triaxle" : "rail",
          delivered: container.delivered == true,
          hub: terminal.hub.name,
        } rescue nil
      end.compact # when edi_customer_code is required for SSLine, can remove compact
    else
      []
    end
  end
end
