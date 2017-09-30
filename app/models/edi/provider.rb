module Edi
  class Provider < ApplicationRecord
    self.table_name = "edi_providers"
    has_many :companies, foreign_key: :edi_provider_id
    has_many :queue_items, -> { order("id") }, foreign_key: :edi_provider_id, class_name: 'Edi::QueueItem'
    has_many :logs, :class_name => "Edi::Log", foreign_key: :edi_provider_id

    def self.process_queues
      minute = Time.now.min
      Edi::Provider.where(active: true).find_each do |provider|
        # I use Sidekiq here as an easy way to handle multi-threading.
        EdiWorker.perform_async(provider.id) if minute % provider.frequency == 0
      end
    end

    def enqueue(document_num, options)
      self.queue_items.create!(document_num: document_num, options: options)
    end

    def handle_network_error(ex)
      if ex.message.rstrip =~ /No files found/
        Rails.logger.info "Checked #{ftp_server} FTP site and found no files"
      else
        OrderMailer.delay.notify_dispatch_edi_breakdown(
          Log.create!(edi_provider: self, :error => ex.to_pretty, :is_inbound => true).id
        )
      end
    end

    def process_queue
      begin
        if queue_items.length > 0
          connect_to_server(:outbound) do |server|
            queue_items.find_each do |queue_item|
              queue_item.process(server)
              queue_item.destroy
            end
          end
        end
        connect_to_server(:inbound) do |server|
          Listener.check_for_messages(server)
        end
      rescue Exception => ex
        Rails.logger.info "#{Time.now} EDI: Abruptly disconnected from server: #{ex.to_pretty}"
        handle_network_error(ex)
      end
    end

    def connect_to_server(direction)
      ((self.send((direction.to_s + "_is_secure").to_sym) ? "Edi::Sf" : "Edi::F") + "tpServer").constantize.connect(self, direction) do |server|
        yield server
      end
    end

  	def needs_n9_for_210?(n9_repeat)
      return true
    end

    def calculate_stop_number(container, operation, options)
      if options[:event_type] == "scheduled"
        return 2
      elsif container.type == 'ImportContainer'
        case operation.operation_type.options_from
        when /Terminal/
          1
        when /Consignee/
          2
        when /Depot/
          3
        end
      else
        case operation.operation_type.options_from
        when /Depot/
          1
        when /Shipper/
          2
        when /Terminal/
          3
        end
      end
    end

    def construct_l11_in_214(transaction, container, options, operation)
      (0..1).each do |l11_repeat|
        transaction.L11.repeat do |l11|
          case l11_repeat
          when 0
            l11.ReferenceIdentification = container.reference_no
            l11.ReferenceIdentificationQualifier = "WO"
          when 1
            l11.ReferenceIdentification = calculate_stop_number(container, operation, options)
            l11.ReferenceIdentificationQualifier = "CMN"
          end
        end
      end
    end

    def set_time_code_in_214(item)
    end

    def set_shipment_status_in_214(at7)
    end


    def base_incoming_dir
      [directory, incoming_dir].compact.join("/")
    end

    def base_outgoing_dir
      [directory, outgoing_dir].compact.join("/")
    end

    def send_invoice_by_edi?
      true
    end

    def invoice_footer
      ""
    end
  end
end