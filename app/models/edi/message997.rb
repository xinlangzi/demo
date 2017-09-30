require 'X12'

module Edi
  # This is the message to send an order to a vendor.
  class Message997
    include ProducerBase

    def initialize(*args)
      obj = args.first
      if obj.instance_of?(HashWithIndifferentAccess)
        super("997", obj[:customer_id])
        @container = Container.find(obj[:container_id]) if obj[:container_id].present?
        @input = obj
        @options = {
          :interchange => {:InterchangeControlVersionNumber => "00400"},
          :group => {:FunctionalIdentifierCode => "FA"},
          :transaction_set => {:TransactionSetIdentifierCode => "997"},
          :inner => [:ak1, :entity, :ak9]
        }
      else
        @parsed_edi, @full, @raw_edi, @index, @log, @customer = args
      end
    end

    def identify_container
    end

    def consume_message
      is_rejection = @parsed_edi.ENTITY.to_a.any? { |entity| entity.AK5.TransactionSetAcknowledgmentCode == "R" }
      OrderMailer.delay.notify_dispatch_edi_997_rejection_arrival(@log.id) if is_rejection
      ts_control_num = @parsed_edi.ENTITY[0].AK2.TransactionSetControlNumber
      unless @parsed_edi.ENTITY[0].AK2.TransactionSetIdentifierCode == "210"
        Rails.logger.info("a 997 response came for #{@parsed_edi.ENTITY[0].AK2.TransactionSetIdentifierCode}!")
        return
      end
      exchanges = Edi::Exchange.joins(:edi_log).where("edi_logs.message LIKE ?", "%ST*210*#{ts_control_num}%")
      containers = exchanges.map(&:container)
      if containers.blank? || containers.length > 1
        OrderMailer.delay.notify_dispatch_unexpected_997_match(@log.id, containers.map(&:id))
        @log
      else
        container = containers.first
        invoice = exchanges.first.invoice
        container.update_attribute(:edi_complete, true) unless is_rejection
        @log.edi_exchanges.create!(container_id: container.id, invoice: invoice, message_type: 997, is_rejection: is_rejection, transaction_pos: @index)
      end
    end

    def self.produce_message(server, object)
      edi = Message997.new(object)
      edi.send_file(server, edi.construct)
    end

    def construct_ak1
      @transaction.AK1 do |ak1|
        ak1.FunctionalIdentifierCode = 'IM'
        ak1.GroupControlNumber = @input[:group_control_number]
      end
      @count += 1
    end

    def construct_entity
      @input[:transactions].each do |trx|
        @transaction.ENTITY.repeat do |entity|
          entity.repeat do |r1|
            r1.AK2 do |ak2|
              ak2.TransactionSetIdentifierCode = trx[:transaction_set_identifier_code]
              ak2.TransactionSetControlNumber = trx[:transaction_set_control_number]
            end

            if trx[:errors]
              trx[:errors].each do |error|
                r1.NOTES.repeat do |note|
                  note.AK3 do |ak3|
                    ak3.SegmentIdCode = error[:segment_id_code]
                    ak3.SegmentPositionInTransactionSet = error[:segment_position_in_transaction_set]
                  end
                  note.AK4 do |ak4|
                    ak4.PositionInSegment = error[:position_in_segment]
                    ak4.DataElementSyntaxErrorCode = error[:data_element_syntax_error_code]
                    ak4.CopyOfBadDataElement = error[:copy_of_bad_data_element]
                  end
                end
              end
            end

            r1.AK5.TransactionSetAcknowledgmentCode = trx[:transaction_set_acknowledgment_code]
            @is_rejection = (trx[:transaction_set_acknowledgment_code] == 'R')
            @count += 2
          end
        end
      end
    end

    def construct_ak9
      @transaction.AK9 do |ak9|
        ak9.FunctionalGroupAcknowledgeCode = @input[:transactions].first[:transaction_set_acknowledgment_code]
        ak9.NumberOfTransactionSetsIncluded = @input[:transactions].length
        ak9.NumberOfReceivedTransactionSets = @input[:transactions].length
        ak9.NumberOfAcceptedTransactionSets = @input[:transactions].length
      end
      @count += 1
    end
  end
end
