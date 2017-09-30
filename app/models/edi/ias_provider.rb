module Edi
  class IasProvider < Edi::Provider
    CONTAINER_TYPE_HASH = {
      "BM" => "IP",
      "BN" => "XP"
    }

    def segment_separator
      "\n"
    end

    def extract_container_type(parsed_edi)
      begin
        CONTAINER_TYPE_HASH[
          parsed_edi.L11.to_a.find { |item| ["BN", "BM"].
            include?(item.ReferenceIdentificationQualifier) }.ReferenceIdentificationQualifier
        ]
      rescue
        raise "Cannot discern container type from L11.ReferenceIdentificationQualifier"
      end
    end

    def extract_reference_no(parsed_edi)
      parsed_edi.L11.to_a.find { |l11| l11.ReferenceIdentificationQualifier == "WO" }.ReferenceIdentification rescue nil
    end

    def extract_ssline_code(parsed_edi)
      parsed_edi.L0100.N1.to_a.find { |item| item.EntityIdentifierCode1 == "CA"}.IdentificationCode
    end

    def extract_size_type_code(parsed_edi, container)
      container.orig_equip_type = parsed_edi.N7.EquipmentType
    end

    def extract_container_no(parsed_edi)
      if extract_container_type(parsed_edi) == "IP"
        parsed_edi.L0300.to_a.find {|item| item.L0350.OID.PurchaseOrderNumber != ""}.L0350.OID.PurchaseOrderNumber rescue nil
      end
    end

    def extract_ssline_bl_no(parsed_edi)
      parsed_edi.L11.to_a.find { |item| item.ReferenceIdentificationQualifier == "BM" }.ReferenceIdentification rescue nil
    end

    def needs_214_message?(operation)
      operation.operation_type.options_from !~ /Yard/
    end

    def required_214_components
      [:b10, :l11, :lx, :at7, :ms2]
    end

    def construct_l11_in_214(transaction, container, options, operation)
      super(transaction, container, options, operation)

      transaction.L11.repeat do |l11|
        l11.ReferenceIdentification = container.orig_equip_type
        l11.ReferenceIdentificationQualifier = "ZZ"
      end
    end

    def get_at7_status_code_in_214(at7, container)
      container.class == ExportContainer ? "LP" : (container.appt_end.nil? ? "AB" : "ED")
    end

    def get_shipment_identification_number_in_214(container)
      container.pickup_no
    end

    def process_entity(entity, container, amendment)
      case entity.N1.EntityIdentifierCode1
      when "SH" then ["Export", Shipper]
      when "T3"
        case container.type
        when "ExportContainer"
          if !amendment && container.operations.none? { |operation| operation.operation_type.options_from =~ /Depot/ }
            ["Export", Depot]
          end
        when "ImportContainer"
          if container.operations.none? { |operation| operation.operation_type.options_from =~ /Terminal/ }
            ["Import", Terminal]
          elsif !amendment
            ["Import", Depot]
          end
        end
      when "CN" then ["Import", Consignee] unless @amendment
      end
    end

    def construct_customer_code(company, document_num)
      company.edi_customer_code
    end

    def construct_interchange_code(company, document_num)
      "USOAKIASA"
    end

    def accept_container(container)
      enqueue(990, {
        container_id: container.id,
        customer_id: container.customer.id,
        group_control_number: container.group_cntrl_num,
        reservation_action_code: "A"
      })
    end

    def reject_container(container)
      enqueue(990, {
        customer_id: container.customer.id,
        group_control_number: container.group_cntrl_num,
        reservation_action_code: "R",
        reference_no: container.reference_no,
        interchange_receiver_id: container.interchange_receiver_id
      })
    end

    def send_invoice_by_edi?
      false
    end

    def invoice_footer
      "Vendor Number: 1079668"
    end
  end
end