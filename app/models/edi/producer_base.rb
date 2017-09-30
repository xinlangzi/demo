require 'net/ftp'

module Edi
  module ProducerBase
    def initialize(document_num, company_id)
      @factory = X12::Parser.new("lib/edi_document_definitions/container.xml").factory("container")
      @transaction = @factory.Transaction.send(document_num.to_sym)
      @company = Company.find(company_id)
      @provider = @company.edi_provider
      @now = Time.now.in_time_zone("Central Time (US & Canada)")
      @count = 1
      @document_num = document_num
      @factory.segment_separator = @provider.segment_separator
    end

    def fill_in_options(options, obj)
      options.each do |key, value|
        obj.send("#{key}=".to_sym, value)
      end
    end

    def interchange(options={})
      x = Interchange.create!.id.to_s.rjust(9, "0")
      construct_isa(x) do |isa|
        fill_in_options(options, isa)
      end
      construct_iea(yield, x)
    end

    def group(options={})
      x = Group.create!.id.to_s.rjust(9, "0")
      construct_gs(x) do |gs|
        fill_in_options(options, gs)
      end
      construct_ge(yield, x)
    end

    def transaction_set(options={})
      x = TransactionSet.create!.id.to_s.rjust(9, "0")
      construct_st(x) do |st|
        fill_in_options(options, st)
      end
      construct_se(yield, x)
    end

    def construct
      interchange(@options[:interchange]) do
        group(@options[:group]) do
          transaction_set(@options[:transaction_set]) do
            @options[:inner].each do |segment|
              self.send("construct_#{segment}")
            end

            @count + 1
          end

          1
        end

        1
      end

      @factory.render
    end

    def send_file(server, message)
      f = Tempfile.new('edi')
      f.write(message)
      Rails.logger.info("EDI: Wrote this to temp file #{f.path}: #{message}")
      f.close
      log = Log.create!(:customer=>@company, :message=>message, :is_inbound => false)
      begin
        name = server.send_file(f, @document_num)
        Rails.logger.info("EDI: Sent content of temp file as #{name}.")
      rescue Exception => ex
        log.update_attribute(:error, ex.to_pretty)
        OrderMailer.delay.notify_dispatch_edi_breakdown(log.id, true)
      end
      if @container.present?
        log.edi_exchanges.create!(container_id: @container.id, invoice: @invoice, message_type: @document_num, is_rejection: @is_rejection, transaction_pos: 0)
      else
        log
      end
    end

    def construct_reference_identification
      @container.type == 'ImportContainer' ? @container.ssline_bl_no : @container.ssline_booking_no
    end

    def construct_own_code
      (@input.present? && @input[:interchange_receiver_id].present?) ?
        @input[:interchange_receiver_id] :
        @container.interchange_receiver_id
    end

    def construct_isa(interchange_number)
      @factory.ISA do |isa|
        isa.AuthorizationInformationQualifier = '00'
        isa.AuthorizationInformation = '          '
        isa.SecurityInformationQualifier = "00"
        isa.SecurityInformation ="          "
        isa.InterchangeIdQualifier1 = "ZZ"
        isa.InterchangeSenderId = construct_own_code.ljust(15)
        isa.InterchangeIdQualifier2="ZZ"
        isa.InterchangeReceiverId = @provider.construct_interchange_code(@company, @document_num).ljust(15)
        isa.InterchangeDate = @now.to_s(:yymmdd)
        isa.InterchangeTime = @now.to_s(:hhmm)
        isa.InterchangeControlStandardsIdentifier = "U"
        isa.InterchangeControlNumber = interchange_number
        isa.AcknowledgmentRequested = ["990", "997"].include?(@document_num) ? "0" : "1"
        isa.UsageIndicator = ENV["RAILS_ENV"] == "production" ? "P" : "T"
        isa.ComponentElementSeparator = ">"
        yield isa
      end
  	end

    def construct_gs(group_number)
  	  @factory.GS do |gs|
        gs.ApplicationSendersCode = construct_own_code
        gs.ApplicationReceiversCode = @provider.construct_customer_code(@company, @document_num)
        gs.Date = @now.to_s(:yyyymmdd)
        gs.Time = @now.to_s(:hhmm)
        gs.GroupControlNumber = group_number
        gs.ResponsibleAgencyCode = 'X'
        gs.VersionReleaseIndustryIdentifierCode = '004010'
        yield gs
      end
    end

  	def construct_st(transaction_set_number)
  	  @factory.Transaction.ST do |st|
        st.TransactionSetControlNumber = transaction_set_number
        yield st
      end
    end

    def construct_se(count, transaction_set_number)
      @factory.Transaction.SE do |se|
        se.NumberOfIncludedSegments = count
        se.TransactionSetControlNumber = transaction_set_number
      end
    end

    def construct_ge(count, group_number)
      @factory.GE do |ge|
        ge.NumberOfTransactionSetsIncluded = count
        ge.GroupControlNumber = group_number
      end
    end

    def construct_iea(count, interchange_number)
      @factory.IEA do |iea|
        iea.NumberOfIncludedFunctionalGroups = count
        iea.InterchangeControlNumber = interchange_number
      end
    end
  end
end
