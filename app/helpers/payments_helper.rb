module PaymentsHelper

  def grouped_categories(selected)
    if in_payable?
      grouped_options = [
        ["Container Charges",
          PayableCharge.all.map do |charge|
            [charge.name, "PayableCharge-#{charge.id}"]
          end
        ],
        ["Third Party Costs",
          Accounting::Category.cost.all.map do |category|
            [category.name, "Accounting::Category-#{category.id}"]
          end
        ]
      ]
    else
      grouped_options = [
        ["Container Charges",
          ReceivableCharge.all.map do |charge|
            [charge.name, "ReceivableCharge-#{charge.id}"]
          end
        ],
        ["Third Party Revenues",
          Accounting::Category.revenue.all.map do |category|
            [category.name, "Accounting::Category-#{category.id}"]
          end
        ]
      ]
    end
    grouped_options_for_select(grouped_options, selected)
  end
end
