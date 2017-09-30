module Edi
  class Log < ApplicationRecord
    self.table_name = "edi_logs"
    paginates_per 25
    has_many :edi_exchanges, class_name: Edi::Exchange, foreign_key: :edi_log_id
    has_many :containers, through: :edi_exchanges
    has_many :invoices, through: :edi_exchanges
    belongs_to :customer
    belongs_to :edi_provider, :class_name => "Edi::Provider"

    before_create do |record|
      record.message = record.message.gsub(/~/, "~\n").gsub(/\n+/m, "\n") if message
    end
  end
end