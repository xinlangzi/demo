module InvoiceBase
  module Invoice
  end

  module PayableInvoice
  end

  module ReceivableInvoice
    TRANSMISSION_PENDING = "Transmission Pending"
    attr_accessor :to_email_now
    def email!(html)
      begin
        self.to_email_now = true #very important to validate sent_to_whom
        self.sent_to_whom = email_to
        self.should_be_emailed = false
        self.date_sent = Time.now
        raise errors.full_messages.join("; ") unless save
        InvoiceMailer.send_invoice(self, html).deliver_now
        set_transmission_status(nil)
        return true
      rescue => ex
        # puts ex.message
        set_transmission_status(ex.message)
      end
      false
    end

    def set_transmission_status(info)
      update_column(:transmission_status, info)
      touch
    end

    def transmission_pending
      set_transmission_status(TRANSMISSION_PENDING)
    end

    def transmission_pending?
      self.transmission_status == TRANSMISSION_PENDING
    end

    def email_to
      @email_to || company.accounting_email || company.email
    end

    def email_to=(email_address)
      @email_to = email_address.blank? ? email_to : email_address
    end

    def email_subject
      (@email_subject || "Invoice no #{number} from #{Owner.itself.name} #{reference_info}").strip
    end

    def reference_info
       "/ #{containers.map(&:reference_no).join(', ')}" rescue ''
    end

    def email_subject=(subject)
      @email_subject = subject.blank? ? email_subject : subject
    end

    def mail_status
      date_sent.nil? ?  'no' : (should_be_emailed ? 'resend' : 'sent')
    end

    def emailx!(invoices, htmls)
      self.to_email_now = true #very important to validate sent_to_whom
      self.sent_to_whom = email_to
      if self.valid?
        InvoiceMailer.emailx(self, htmls).deliver_now
        invoices.each do |invoice|
          invoice.sent_to_whom = sent_to_whom
          invoice.should_be_emailed = false
          invoice.date_sent = Time.now
          invoice.save
        end
        true
      else
        false
      end
    end

  end

end
