# class AccountingFilter < Filter
#   attr_accessor :issue_date_from, :issue_date_to, :cleared_date_from, :cleared_date_to, :unpaid

#   def receivable_container_charges
#     container_charges("Receivable")
#   end

#   def payable_container_charges
#     container_charges("Payable")
#   end

#   def tp_receivable_line_items
#     tp_line_items("Receivable")
#   end

#   def tp_payable_line_items
#     tp_line_items("Payable")
#   end

#   def container_charges(type)
#     join_tables = [:company, { line_item: :invoice }]
#     join_payment = "LEFT OUTER JOIN `line_item_payments` ON `line_item_payments`.`line_item_id` = `line_items`.`id` LEFT OUTER JOIN `payments` ON `payments`.`id` = `line_item_payments`.`payment_id`"
#     select_clause = "container_charges.container_id, invoices.number, line_items.invoice_id, container_charges.chargable_type, container_charges.chargable_id, companies.name AS company_name"
#     select_clause = "#{select_clause}, container_charges.amount * IFNULL(line_item_payments.amount, line_items.amount)/line_items.amount AS amount"
#     where_clause = "(chargable_type = '#{type}Charge' AND chargable_id IN (#{charges.to_sql})) OR (chargable_type = 'Accounting::Category' AND chargable_id IN (#{categories.to_sql}))"
#     relation = ContainerCharge.select(select_clause).joins(join_tables).joins(join_payment).where(where_clause)
#     relation = relation.where("container_charges.type IN ('#{type}ContainerCharge')")
#     relation = date_range_clause(relation)
#     unpaid_clause(relation)
#   end

#   def tp_line_items(type)
#     join_tables = [:category, { invoice: :company }]
#     join_payment = "LEFT OUTER JOIN `line_item_payments` ON `line_item_payments`.`line_item_id` = `line_items`.`id` LEFT OUTER JOIN `payments` ON `payments`.`id` = `line_item_payments`.`payment_id`"
#     select_clause = "invoices.number, accounting_categories.name AS category_name, line_items.invoice_id, line_items.amount, companies.name AS company_name"
#     where_clause = "category_id IN (#{categories.to_sql})"
#     relation = LineItem.select(select_clause).joins(join_tables).joins(join_payment).where(where_clause)
#     relation = relation.where("line_items.type IN ('Accounting::#{type}LineItem')")
#     relation = date_range_clause(relation)
#     unpaid_clause(relation)
#   end

#   def date_range_clause(relation)
#     relation = relation.where("invoices.issue_date >= ?", issue_date_from) if issue_date_from.present?
#     relation = relation.where("invoices.issue_date <= ?", issue_date_to) if issue_date_to.present?
#     relation = relation.where("payments.cleared_date >= ?", cleared_date_from) if cleared_date_from.present?
#     relation = relation.where("payments.cleared_date <= ?", cleared_date_to) if cleared_date_to.present?
#     relation
#   end

#   def unpaid_clause(relation)
#     relation = relation.where("invoices.amount = invoices.balance") if unpaid.to_boolean
#     relation
#   end

#   def default_date_range!
#     self.issue_date_from||= 1.month.ago.to_date
#     self.issue_date_to||= Date.today
#   end
# end