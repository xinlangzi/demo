module Payable
  def number_to_words(dollar_amount)
    Linguistics::use(:en)
    dollars = dollar_amount.truncate.en.numwords
    dollars.gsub!(" point zero","")
    cents = ((dollar_amount*100) % (dollar_amount.truncate)*100)/100
    dollars + " and " + sprintf("%02d", cents.to_i) + "/100"
  end

  def get_check_details(override = nil)
    {
      customer_name: company.print_name,
      customer_address_street: override.present? ? override[:address_street] : company.address_street,
      customer_address_street_2: override.present? ? override[:address_street_2] : company.address_street_2,
      customer_address_city: override.present? ? "#{override[:address_city]} #{State.find(override[:address_state_id]).abbrev} #{override[:zip_code]}" : "#{company.address_city} #{company.state} #{company.zip_code}",
      check_amount: sprintf("%.2f", amount),
      check_amount_words: number_to_words(amount),
      check_date: created_at.strftime("%B %e, %Y")
    }
  end
end
