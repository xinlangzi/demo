class Edi::CmaProvider < Edi::Provider
  ENTITY_MAPPING = {
    "PW" => ["Export", Shipper],
    "DA" => ["Import", Consignee],
    "OT" => ["Import", Terminal],
    "DT" => ["Export", Terminal],
    "WD" => ["Import", Depot],
    "WO" => ["Export", Depot],
  }

  def segment_separator
    "~"
  end

  def extract_container_type(parsed_edi)
    begin
      parsed_edi.AT5.to_a.find { |item| ["IP", "XP"].include?(item.SpecialHandlingCode) }.SpecialHandlingCode
    rescue
      raise "Cannot discern container type from AT5.SpecialHandlingCode"
    end
  end

  def extract_reference_no(parsed_edi)
    parsed_edi.B2.ShipmentIdentificationNumber.split("_").first
  end

  def extract_ssline_code(parsed_edi)
    parsed_edi.B2.StandardCarrierAlphaCode
  end

  def extract_size_type_code(parsed_edi, container)
    parsed_edi.N7.EquipmentLength
  end

  def extract_container_no(parsed_edi)
    parsed_edi.L11.to_a.find { |item| item.ReferenceIdentificationQualifier == "OC" }.ReferenceIdentification rescue nil
  end

  def extract_ssline_bl_no(parsed_edi)
    parsed_edi.L11.to_a.find { |l11| ["BL", "OB"].include?(l11.ReferenceIdentificationQualifier) }.ReferenceIdentification rescue nil
  end

	def needs_n9_for_210?(n9_repeat)
    return n9_repeat != 2
  end

  def needs_214_message?(operation)
    operation.operation_type.options_from =~ /Consignee/ || operation.operation_type.options_from =~ /Shipper/
  end

  def required_214_components
    [:b10, :lx, :at7, :ms2]
  end

  def set_time_code_in_214(item)
    item.TimeCode = "LT"
  end

  def get_at7_status_code_in_214(at7, container)
    at7.ShipmentStatusOrAppointmentReasonCode2 = "NA"
    container.class == ExportContainer ? "AA" : "AB"
  end

  def set_shipment_status_in_214(at7)
    at7.ShipmentStatusOrAppointmentReasonCode1 = "NS"
  end

  def get_shipment_identification_number_in_214(container)
    container.reference_no
  end

  def process_entity(entity, container, amendment)
    return ENTITY_MAPPING[entity.N1.EntityIdentifierCode1]
  end

  def construct_customer_code(company, document_num)
    company.edi_customer_code + (document_num == "214" ? "214" : "")
  end

  def construct_interchange_code(company, document_num)
    construct_customer_code(company, document_num)
  end

  def accept_container(container)
    enqueue(997, {
      :container_id => container.id,
      :customer_id=>container.customer.id,
      :group_control_number=>container.group_cntrl_num,
      :transactions => [{
        :transaction_set_control_number => container.trans_set_cntrl_num,
        :transaction_set_identifier_code => "204",
        :transaction_set_acknowledgment_code=>"A"
      }]
    })
  end

  def reject_container(container)
    enqueue(997, {
      :customer_id=>container.customer.id,
      :group_control_number=>container.group_cntrl_num,
      interchange_receiver_id: container.interchange_receiver_id,
      :transactions => [{
        :transaction_set_control_number => container.trans_set_cntrl_num,
        :transaction_set_identifier_code => "204",
        :transaction_set_acknowledgment_code=>"R",
        :errors => compute_rejection_reason(container)
      }]
    })
  end

  def compute_rejection_reason(container)
    container.container_edi_detail.raw_message =~ /(^ST.*)/m
    raw = $1.split("\n")
    container.save

    ret_val = []

    container.errors.each do |error|
      case error
      when :container_size_id#, :container_type_id
        index = raw.find_index { |line| line =~ /^N7/ }
        value = raw[index].split("*")[15]
        ret_val <<  {
          :segment_id_code => "N7",
          :segment_position_in_transaction_set => (index + 1).to_s,
          :position_in_segment => "15", # KHNN-CLT might be "22"
          :copy_of_bad_data_element => value,
          :data_element_syntax_error_code => value == "" ? "1" : "7"
        }
      when :weight
        index = raw.find_index { |line| line =~ /^N7/ }
        value = raw[index].split("*")[3]
        ret_val <<  {
          :segment_id_code => "N7",
          :segment_position_in_transaction_set => (index + 1).to_s,
          :position_in_segment => "3",
          :copy_of_bad_data_element => value,
          :data_element_syntax_error_code => value == "" ? "1" : "7"
        }
      when :commodity
        index = raw.find_index { |line| line =~ /^L5/ }
        value = raw[index].split("*")[2]
        ret_val <<  {
          :segment_id_code => "L5",
          :segment_position_in_transaction_set => (index + 1).to_s,
          :position_in_segment => "2",
          :copy_of_bad_data_element => value,
          :data_element_syntax_error_code => value == "" ? "1" : "7"
        }
      end
    end

    ret_val
  end
end
