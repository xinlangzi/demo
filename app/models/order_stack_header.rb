class OrderStackHeader < Header
  COLUMNS = [
    "ID",
    "Lock",
    "Date",
    "Consignee/Shipper",
    "City",
    "State",
    "Cont. No.",
    "Chassis No.",
    "Terminal",
    "Triaxle",
    "Operations",
    "Customer",
    "Payable Invoice(s)",
    "Payable Amount",
    "Payable Payment(s)",
    "Receivable Invoice(s)",
    "Receivable Amount",
    "Receivable Payment(s)",
    "Admin Comments"
  ].freeze
end