# class ProfitLossFilter < AccountingFilter

#   def charges
#     Charge.joins(:accounting_group).where("accounting_groups.profit_loss = ?", true).select(:id)
#   end

#   def categories
#     Accounting::Category.joins(:accounting_group).where("accounting_groups.profit_loss = ?", true).select(:id)
#   end

# end