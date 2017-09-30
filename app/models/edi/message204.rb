require 'X12'
module Edi
  # This is the message to send an order to a vendor.
  class Message204
    SIZE_MAP = {
      "2030" => "20 RF",
      "2050" => "20 OT",
      "2060" => "20 FR",
      "20T0" => "20 TANK",
      "2200" => "20 DV",
      "2210" => "20 DV",
      "2232" => "20 RF",
      "40RQ" => "40 HC",
      "40TK" => "40 TANK",
      "4130" => "40 RF",
      "4200" => "40 DV",
      "4310" => "40 DV",
      "4330" => "40 RF",
      "4352" => "40 OT",
      "4500" => "40 HC",
      "4510" => "40 HC",
      "4532" => "40 HC",
      "4566" => "40 HC",
      "4750" => "40 OT",
      "48P0" => "40 FR"
    }

    def initialize(transaction, full, raw_edi, index, log, customer)
      @raw_edi = raw_edi
      @parsed_edi = transaction
      @full = full
      @index = index
      @log = log
      @customer = customer
      @provider = customer.edi_provider
    end

    def add_operation(entity, container_type, company_type)
      company = company_type == Terminal ?
        company_type.find_by_name(entity.N1.Name) :
        company_type.exact_address_match(
          entity.N4.PostalCode,
          entity.N4.StateOrProvinceCode,
          entity.N4.CityName,
          [entity.N3.AddressInformation1, entity.N3.AddressInformation2]
        ).first

      return unless company.present?

      ot = OperationType.where("container_type = ? AND options_from LIKE '%#{company_type.name}%' AND otype IS NULL", container_type).first

      if ot.present?
        pos = @container.operations.map(&:pos).max.to_i + 1
        @container.operations.build(company: company, operation_type: ot, pos: pos)
      end
    end

    def process_entity(entity)
      # This is commented out because of https://github.com/truckerzoom/tz/issues/642
      # args = @provider.process_entity(entity, @container, @amendment)
      # add_operation(entity, args.first, args.last) if args
    end

    def process_L0100_entities
      @parsed_edi.L0100.to_a.each do |entity|
        process_entity(entity)
        @container.admin_comment += (" " + [
           entity.G61.ContactFunctionCode,
           entity.G61.Name,
           entity.G61.CommunicationNumberQualifier,
           entity.G61.CommunicationNumber,
           entity.G61.ContactInquiryReference
         ].join(" "))
      end
    end

    def process_L0300_entities
      @parsed_edi.L0300.to_a.each do |entity|
        process_g62(entity)
        process_nte(entity)
        process_entity(entity.L0310[0])
        @container.commodity = entity.L0320[0].L5.LadingDescription unless entity.L5.LadingDescription.blank?
      end
    end

    def process_nte(parent)
      note = parent.NTE.to_a.map(&:Description).join(" ")
      @container.admin_comment += (" " + note) unless note.blank?
    end

    def process_g62(parent)
      @container.admin_comment += (" " + [
        parent.G62.Date,
        parent.G62.Time
      ].join(" "))
    end

    def extract_ssline
      Ssline.find_by_edi_customer_code(@provider.extract_ssline_code(@parsed_edi))
    end

    def extract_size_and_type
      parts = SIZE_MAP[@provider.extract_size_type_code(@parsed_edi, @container)].to_s.split(" ")
      [ContainerSize.find_by_name(parts.first), ContainerType.find_by_name(parts.last)]
    end

    def extract_ssline_booking_no
      @parsed_edi.L11.to_a.find { |l11| l11.ReferenceIdentificationQualifier == "BN" }.ReferenceIdentification rescue nil
    end

    def init_admin_comment
      @container.admin_comment = ""
      @parsed_edi.L11.to_a.select { |l11| l11.ReferenceIdentificationQualifier == "PO" }.each do
        @container.admin_comment += "PO: #{l11.ReferenceIdentification}"
      end
    end

    def amend_order
      @container = find_exact_match_container
      if @container
        @amendment = true
        fill_out_order
        OrderMailer.delay.notify_dispatch_amend_known_edi_order(@container.id)
        @container.accept_container
        @log.edi_exchanges.create!(container_id: @container.id, message_type: 204, transaction_pos: @index)
      else
        OrderMailer.delay.notify_dispatch_amend_unknown_edi_order(@log.id, @conditions)
        @log
      end
    end

    def create_order
      @container = case @provider.extract_container_type(@parsed_edi)
      when "IP"
        ImportContainer.new(
          customer: @customer, operation_type_ids: Settings.default_operations["/import_containers/new"],
          chassis_pickup_with_container: true, chassis_return_with_container: true
        )
      when "XP"
        ExportContainer.new(
          customer: @customer, operation_type_ids: Settings.default_operations["/export_containers/new"],
          chassis_pickup_with_container: true, chassis_return_with_container: true
        )
      end
      @container.to_save = true
      @container.needs_edi_review = true
      @container.edi_complete = false
      @amendment = false
      fill_out_order
    end

    # Currently this method is never called since TZ likes to have more granular charges.
    def add_charges
      charge = ReceivableCharge.first
      @container.receivable_container_charges.update_collection(
        (-rand(99999999999)).to_s => {
          amount: @parsed_edi.L3.Charge.to_f / 100,
          company_id: @container.customer.id,
          chargable: charge
        }
      ) unless @parsed_edi.L3.Charge == ""
    end

    def fill_out_order
      @container.group_cntrl_num = @full.GS.GroupControlNumber
      @container.trans_set_cntrl_num = @parsed_edi.ST.TransactionSetControlNumber
      @container.ssline = extract_ssline unless @amendment
      @container.reference_no = @provider.extract_reference_no(@parsed_edi)
      @container.weight_decimal_humanized = @parsed_edi.L0200.N7.Weight
      @container.weight_is_metric = "true" if @parsed_edi.L0200.N7.WeightUnitCode == 'K'
      @container.container_size, @container.container_type = extract_size_and_type

      @container.container_no = @provider.extract_container_no(@parsed_edi)
      @container.seal_no = @parsed_edi.M7.SealNumber1
      @container.ssline_bl_no = @provider.extract_ssline_bl_no(@parsed_edi)
      @container.ssline_booking_no = extract_ssline_booking_no
      irid = @full.ISA.InterchangeReceiverId.strip
      @container.interchange_receiver_id = irid
      @container.hub_id = HubInterchange.find_by(edi: irid, customer_id: @customer.id).try(:hub_id)
      raise "Unknown Interchange Receiver ID: #{irid}" unless @container.hub_id
      init_admin_comment

      process_g62(@parsed_edi)
      process_nte(@parsed_edi)

      process_L0100_entities
      process_L0300_entities

      @container.admin_comment.strip!

      @container.save(validate: false)
      @log.edi_exchanges.create!(container_id: @container.id, message_type: 204, transaction_pos: @index)

      if @amendment
        @container.container_edi_detail.update_attributes!(:raw_message=>@raw_edi.gsub(/\n*/, "").gsub(/~/, "~\n"), :parsed_message=>@full.pretty_print)
      else
        @container.create_container_edi_detail(:raw_message=>@raw_edi.gsub(/\n*/, "").gsub(/~/, "~\n"), :parsed_message=>@full.pretty_print)
      end

      @container
    end

    def find_exact_match_container
      @conditions = { :container_no => @provider.extract_container_no(@parsed_edi), :reference_no => @provider.extract_reference_no(@parsed_edi), :customer_id => @customer.id }.merge!(
        case @provider.extract_container_type(@parsed_edi)
        when "IP"
          { :type => "ImportContainer", :ssline_bl_no => @provider.extract_ssline_bl_no(@parsed_edi) }
        when "XP"
          { :type => "ExportContainer", :ssline_booking_no => extract_ssline_booking_no }
        end
      )

      Container.where(@conditions).order("id desc").first
    end

    def cancel_order
      container = find_exact_match_container

      if container
        container.cancelled = true
        container.save(validate: false)
        OrderMailer.delay.notify_dispatch_edi_cancel_known_order(container.id)
        @log.edi_exchanges.create!(container_id: container.id, message_type: 204, transaction_pos: @index)
      else
        OrderMailer.delay.notify_dispatch_edi_cancel_unknown_order(@log.id, @conditions)
        @log
      end
    end

    def consume_message
      case @parsed_edi.B2A.TransactionSetPurposeCode
      when '00' then create_order
      when '01' then cancel_order
      when '04' then amend_order
      else raise "Unknown B2A.TransactionSetPurposeCode: #{@parsed_edi.B2A.TransactionSetPurposeCode}"
      end
    end
  end
end
