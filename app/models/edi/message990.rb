require 'X12'

module Edi
  # This is the message to send an order to a vendor.
  class Message990
    include ProducerBase

    def initialize(*args)
      obj = args.first
      if obj.instance_of?(HashWithIndifferentAccess)
        super("990", obj[:customer_id])
        @container = Container.find(obj[:container_id]) if obj[:container_id].present?
        @input = obj
        @options = {
          :interchange => {:InterchangeControlVersionNumber => "00401"},
          :group => {:FunctionalIdentifierCode => "GF"},
          :transaction_set => {:TransactionSetIdentifierCode => "990"},
          :inner => [:b1, :n9]
        }
      else
        @parsed_edi, @full, @raw_edi, @index, @log, @customer = args
      end
    end

    def consume_message
      instance = @parsed_edi.send("990".to_sym)[0]
      is_rejection = ["R", "D"].include?(instance.B1.ReservationActionCode)
      OrderMailer.delay.notify_dispatch_edi_997_rejection_arrival(@log.id) if is_rejection
      container = Container.where(reference_no: instance.N9.ReferenceIdentification).first
      if container
        @log.edi_exchanges.create!(container_id: container.id, message_type: 990, is_rejection: is_rejection, transaction_pos: @index)
      else
        # really should send email
        @log
      end
    end

    def self.produce_message(server, object)
      edi = Message990.new(object)
      edi.send_file(server, edi.construct)
    end

    def construct_b1
      @transaction.B1 do |b1|
        b1.ReservationActionCode = @input[:reservation_action_code]
      end
      @count += 1
    end

    def construct_n9
      @transaction.N9 do |n9|
        n9.ReferenceIdentificationQualifier = 'WO'
        n9.ReferenceIdentification = @container.present? ? @container.reference_no : @input[:reference_no]
      end
      @count += 1
    end
  end
end
