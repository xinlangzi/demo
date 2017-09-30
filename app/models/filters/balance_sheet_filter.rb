# class BalanceSheetFilter < AccountingFilter

#   def charges
#     Charge.joins(:accounting_group).where("accounting_groups.balance_sheet = ?", true).select(:id)
#   end

#   def categories
#     Accounting::Category.joins(:accounting_group).where("accounting_groups.balance_sheet = ?", true).select(:id)
#   end

# end