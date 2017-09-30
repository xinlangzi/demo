require 'X12'

module Edi
  # This is the message to send an invoice to a customer.
  class Message210
    include ProducerBase
    def self.produce_message(server, options)
      invoice = Invoice.find(options[:invoice_id])
      edi = Message210.new(invoice)
      body = edi.construct
      exchange = edi.send_file(server, body)
      if exchange.edi_log.error.nil?
        invoice.update(should_be_emailed: false, date_sent: Time.now)
        invoice.set_transmission_status(nil)
        body =~ /ST\*210\*(\d+)/
        Exchange.delay_for(35.minutes).check_for_997(invoice.id, $1)
      else
        invoice.update(should_be_emailed: true, date_sent: nil)
        invoice.set_transmission_status(exchange.edi_log.error.try(:lines).try(:first))
      end
      exchange
    end

    def initialize(invoice)
      super("210", invoice.company.id)
      @invoice = invoice
      @options = {
        :interchange => {:InterchangeControlVersionNumber => "00401"},
        :group => {:FunctionalIdentifierCode => "IM"},
        :transaction_set => {:TransactionSetIdentifierCode => "210"},
        :inner => [:b3, :c3, :n9, :ad, :n7, :lx_loop]
      }
      @container = @invoice.line_items.first.container
    end

  	def construct_b3
      @transaction.B3 do |b3|
        b3.InvoiceNumber = @invoice.number
        b3.ShipmentIdentificationNumber = @container.reference_no
        b3.ShipmentMethodOfPayment = "TP"
        b3.WeightUnitCode = "L"
        b3.Date1 = @invoice.date.to_s(:yyyymmdd)
        b3.NetAmountDue = ((@invoice.amount + @invoice.sum_adjustments) * 100).to_i
        b3.DeliveryDate = @container.delivered_date.to_s(:yyyymmdd)
        b3.DateTimeQualifier = "035"
        b3.StandardCarrierAlphaCode = "RIIL"
      end
      @count += 1
    end

  	def construct_c3
      @transaction.C3 do |c3|
        c3.CurrencyCode1='USD'
      end
      @count += 1
    end

  	def construct_n9
      (0..2).each do |n9_repeat|
        if @provider.needs_n9_for_210?(n9_repeat)
          @transaction.N9.repeat do |n9|
            case n9_repeat
            when 0
              n9.ReferenceIdentificationQualifier = "PO"
              n9.ReferenceIdentification = @container.reference_no
            when 1
              n9.ReferenceIdentificationQualifier = "BM"
              n9.ReferenceIdentification = construct_reference_identification
            when 2
              n9.ReferenceIdentificationQualifier = "CN"
              n9.ReferenceIdentification = @invoice.number
            end
          end
          @count += 1
        end
      end
    end

  	def construct_ad
  	  [[@company, "SH"], [Owner.itself, "CN"]].each do |record|
  	    company = record.first
        @transaction.AD.repeat do |r1|
          r1.N1.EntityIdentifierCode1 = record.last
          r1.N1.Name = company.name
          @count += 1

          r1.N3.AddressInformation1 = company.address_street
          @count += 1

          r1.N4.CityName = company.address_city
          r1.N4.StateOrProvinceCode = company.state
          r1.N4.PostalCode = company.zip_code
          r1.N4.CountryCode = company.address_country
          @count += 1
        end
      end
    end

  	def construct_n7
      @transaction.N7 do |n7|
        n7.EquipmentInitial = @container.container_no[0..3]
        n7.EquipmentNumber = @container.container_no[4..-1]
      end
      @count += 1
    end

  	def construct_lx_loop
      @transaction.LX_LOOP do |lx|
        @container.charges("receivable", @invoice.company.id).each_with_index do |charge, index|
          lx.repeat do |l|
            l.LX.AssignedNumber = index + 1
            @count += 1

            l.L5.LadingLineItemNumber = index + 1
            l.L5.CommodityCode1 = "RTP" #FROM R2R DB  "FSC"
            l.L5.CommodityCodeQualifier1 = "Z"
            @count += 1

            l.L1.LadingLineItemNumber = index + 1
            l.L1.FreightRate = (charge.amount * 100).to_i
            l.L1.RateValueQualifier1 = "FR" #ASK ASK ASK FROM R2R DB / COMPUTED [Freight Rate => Base Rate]
            l.L1.Charge = (charge.amount * 100).to_i
            l.L1.PrepaidAmount = 0 #wont ever be one
            l.L1.SpecialChargeOrAllowanceCode = "RTP" # UNSUPPORTED - BUT MUST BE PRESENT
            @count += 1
          end
        end
      end
    end
  end
end
