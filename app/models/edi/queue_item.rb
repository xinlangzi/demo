module Edi
  class QueueItem < ApplicationRecord
    self.table_name = "edi_queue_items"
    belongs_to :edi_provider, class_name: "Edi::Provider"

    store :options, coder: JSON

    def process(server)
      begin
        Edi.const_get("Message#{self.document_num}").produce_message(server, HashWithIndifferentAccess.new(self.options))
      rescue ActiveRecord::RecordNotFound => ex
        customer = Customer.find_by(id: options[:customer_id])
        edi_provider.logs.create!(error: "trying to send #{self.document_num} message for non-existent container with parameters #{self.options}. Giving up.", is_inbound: false, customer: customer)
      rescue => ex
        customer = Customer.find_by(id: options[:customer_id])
        edi_provider.logs.create!(error: "Unsuccessfully trying to construct #{self.document_num} message with parameters #{self.options}. Giving up.", is_inbound: false, customer: customer)
        if self.document_num == 210
          OrderMailer.delay.notify_owner_edi_invoice_failure(self.options[:invoice_id])
        end
      end
    end
  end
end
