module Edi
  class Exchange < ApplicationRecord
    self.table_name = "edi_exchanges"

    belongs_to :container
    belongs_to :edi_log, class_name: Edi::Log
    belongs_to :invoice

    def self.check_for_997(invoice_id, ts_control_num)
      ack_exchange = Edi::Exchange.
        joins(:edi_log).
        where("edi_logs.message LIKE ?", "%AK2*210*#{ts_control_num}%").
        where(invoice_id: invoice_id, message_type: 997, is_rejection: false).first

      unless ack_exchange
        invoice_exchange = Edi::Exchange.
          joins(:edi_log).
          where("edi_logs.message LIKE ?", "%ST*210*#{ts_control_num}%").
          where(invoice_id: invoice_id, message_type: 210).first
        OrderMailer.delay.notify_dispatch_unacknowledged_invoice(invoice_id, invoice_exchange.edi_log_id)
      end
    end
  end
end
