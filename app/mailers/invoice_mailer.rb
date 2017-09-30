class InvoiceMailer < MailerBase

  def send_invoice(invoice, html)
    @owner = Owner.first
    attachments["invoice #{invoice.number}.pdf"] = invoice.to_pdf(html)
    mail(
      from: SystemSetting.default.invoice_statement_from,
      to: invoice.email_to,
      subject: invoice.email_subject
    ) do |format|
      format.html { render 'thanks' }
    end
  end

  def emailx(invoice, htmls)
    @owner = Owner.first
    htmls.each do |number, html|
      attachments["invoice #{number}.pdf"] = Wisepdf::Writer.new.to_pdf(html, page_size: "letter", margin: { top: 5, bottom: 5, left: 5, right: 5 })
    end
    mail(
      from: SystemSetting.default.invoice_statement_from,
      to: invoice.email_to,
      subject: invoice.email_subject
    ) do |format|
      format.html { render 'thanks'}
    end
  end

  def send_statement(invoice_statement)
    @owner = Owner.first
    @invoice_statement = invoice_statement
    attachments["#{Date.today.ymd}-invoice-statement.pdf"] = Wisepdf::Writer.new.to_pdf(
      @invoice_statement.data,
      page_size: "letter",
      margin: { top: 5, bottom: 5, left: 5, right: 5 }
    )
    mail(
      subject: @invoice_statement.subject,
      from: @invoice_statement.from,
      to: @invoice_statement.to,
      bcc: [@invoice_statement.bcc]
    )
  end
end
