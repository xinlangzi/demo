require 'X12'

module Edi
  # This is the message to send a status message to a customer.
  class Message214
    include ProducerBase
    TIME_ZONE = "Central Time (US & Canada)"
    def self.produce_message(server, options)
      container = Container.find(options[:container_id])

      if options[:event_type] == "actual"
        operation = Operation.find(options[:operation_id])
        return unless container.customer.edi_provider.needs_214_message?(operation)
      end

      edi = Message214.new(container, operation, options)
      edi.send_file(server, edi.construct)
    end

    def initialize(container, operation, options)
      super("214", container.customer.id)
      @container = container
      @operation = operation
      @options = options.merge({
        interchange: {:InterchangeControlVersionNumber => "00400"},
        group: {:FunctionalIdentifierCode => "QM"},
        transaction_set: {:TransactionSetIdentifierCode => "214"},
        inner: @provider.required_214_components
      })
    end

    def construct_lx
      @transaction.LX do |lx|
        lx.AssignedNumber = 1
      end
      @count += 1
    end

    def construct_l11
      @provider.construct_l11_in_214(@transaction, @container, @options, @operation)
    end

    def construct_generic_at7(item, values, actual)
      if actual
        item.ShipmentStatusCode = values[:status_code]
      else
        item.ShipmentAppointmentStatusCode = values[:status_code]
      end

      @provider.set_time_code_in_214(item)
      item.Date = values[:date].to_s(:yyyymmdd)
      item.Time = values[:time].to_s(:hhmm)
      @count += 1
    end

    def construct_scheduled_at7
      @transaction.AT7 do |at7|
        construct_generic_at7(at7, {
          status_code: @provider.get_at7_status_code_in_214(at7, @container),
          date: @container.appt_date,
          time: (Time.local(2000, 1, 1, @container.appt_start.hour, @container.appt_start.min, @container.appt_start.sec) rescue Time.local(2000, 1, 1, 0, 0, 0))
        }, false)
      end
    end

    def construct_actual_at7
      @transaction.AT7 do |at7|
        @provider.set_shipment_status_in_214(at7)
        raw = @operation.operated_at
        ot = @operation.operation_type

        status_code = case ot.options_from
        when /Consignee/ then 'X1'
        when /Shipper/ then 'X3'
        else 'X4'
        end

        if raw.present?
          date = raw.in_time_zone(TIME_ZONE)
          construct_generic_at7(at7, {
            status_code: status_code,
            date: date.to_date,
            time: date
          }, true)
        end
      end
    end

    def construct_at7
      self.send("construct_#{@options[:event_type]}_at7".to_sym)
    end

    def construct_b10
      @transaction.B10 do |b10|
        b10.ReferenceIdentification1 = construct_reference_identification
        b10.ShipmentIdentificationNumber = @provider.get_shipment_identification_number_in_214(@container)
        b10.StandardCarrierAlphaCode = @container.interchange_receiver_id
        b10.InquiryRequestNumber = nil
        b10.ReferenceIdentificationQualifier = nil
        b10.ReferenceIdentification2 = nil
        b10.YesNoConditionOrResponseCode = nil
        b10.Date = nil
        b10.Time = nil
      end
      @count += 1
    end

    def construct_ms2
      @transaction.MS2 do |ms2|
        ms2.StandardCarrierAlphaCode = @container.container_no[0..3]
        ms2.EquipmentNumber = @container.container_no[4..-1]
        ms2.EquipmentDescriptionCode = "CN"
        ms2.EquipmentNumberCheckDigit = nil
      end
      @count += 1
    end
  end
end
