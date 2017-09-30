module Report
  module BasesHelper
    include ContainersHelper

    def chassis_invoice_days_label(days)
      case true
      when days >= -1
        content_tag(:span, days, class: 'green bold')
      when days == -2
        content_tag(:span, days, class: 'brown bold')
      else
        content_tag(:span, days, class: 'red bold')
      end
    end
  end
end