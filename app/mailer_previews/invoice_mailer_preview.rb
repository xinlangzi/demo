class InvoiceMailerPreview < ActionMailer::Preview

  def send_invoice
    invoice = ReceivableInvoice.last
    invoice.company.update(invoice_j1s: nil)
    html = "<p>Please check the attached PDF with new invoice information. Thank you for making businiess with us</p>"
    InvoiceMailer.send_invoice(invoice, html)
  end

  def send_invoice_with_pod
    invoice = ReceivableInvoice.last
    customer = invoice.company
    customer.pod_j1s!
    container = invoice.containers.first
    operation = container.operations.select(&:delivery_mark?).first
    operation.images.delete_all
    doc = operation.images.build
    doc.file = File.open(Rails.root.join('spec/fixtures/attach.png'))
    doc.user = operation.trucker
    doc.save(validate: false)
    doc.approve!
    html = "<p>Please check the attached PDF with new invoice information. Thank you for making businiess with us</p>"
    InvoiceMailer.send_invoice(invoice, html)
  end

  def send_invoice_with_all_j1s
    invoice = ReceivableInvoice.find(68524)
    customer = invoice.company
    customer.all_j1s!
    container = invoice.containers.first
    container.operations.each do |operation|
      if operation.trucker
        operation.images.delete_all
        doc = operation.images.build
        doc.file = File.open(Rails.root.join('spec/fixtures/attach.png'))
        doc.user = operation.trucker
        doc.save(validate: false)
        doc.approve!
      end
    end
    html = "<p>Please check the attached PDF with new invoice information. Thank you for making businiess with us</p>"
    InvoiceMailer.send_invoice(invoice, html)
  end

  def emailx
    invoice = ReceivableInvoice.last
    htmls = ["<p>Please check the attached PDF with new invoice information. Thank you for making businiess with us</p>"]
    InvoiceMailer.send_invoice(invoice, htmls)
  end

  def send_statement
    customer = Customer.order('updated_at desc').first
    InvoiceMailer.send_statement(InvoiceStatement.init(customer))
  end

end
