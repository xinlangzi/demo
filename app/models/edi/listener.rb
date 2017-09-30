module Edi
  class Listener
    def self.check_for_messages(server)
      server.for_each do |raw|
        Rails.logger.info("#{Time.now} EDI: Retrieved this content:\n#{raw}")
        parse(raw)
      end
    end

    def self.handle_content_error(log, ex)
      log.update_attribute(:error, ex.to_pretty)
      OrderMailer.delay.notify_dispatch_bad_edi_order(log.id)
    end

    def self.preliminary_validations(full)
      customer = Customer.find_by_edi_customer_code(full.ISA.InterchangeSenderId) || Customer.find_by_edi_customer_code(full.GS.ApplicationSendersCode)
      unless customer
        raise "Cannot find a customer with Edi Customer Code of #{full.GS.ApplicationSendersCode}. Aborting."
      end

      if full.ISA.UsageIndicator == "T" && ENV["RAILS_ENV"] == "production"
        raise "A test message was received in the production environment. Aborting."
      end

      if full.ISA.UsageIndicator == "P" && ENV["RAILS_ENV"] != "production"
        raise "A production message was received in a non-production environment. Aborting."
      end

      customer
    end

    def self.parse(raw)
      log = Edi::Log.create!(message: raw, is_inbound: true)
      retval = [ ]

      begin
        full = X12::Parser.new('lib/edi_document_definitions/container.xml').parse('container', raw)
        customer = preliminary_validations(full)
        log.update_attribute(:customer, customer)
        full.Transaction.to_a.each_with_index do |transaction, index|
          retval << Edi.const_get("Message#{transaction.ST.TransactionSetIdentifierCode}").new(transaction, full, raw, index, log, customer).consume_message
        end
      rescue => ex
        retval << log
        handle_content_error(log, ex)
      end

      retval
    end
  end
end
