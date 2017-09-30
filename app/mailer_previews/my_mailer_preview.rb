class MyMailerPreview < ActionMailer::Preview

  def send_drivers_email
    params = { truckers: Trucker.active.take(3).map(&:id), message: 'Please remember to submit your day log.' }
    MyMailer.send_drivers_email(params)
  end

  def send_customers_email
    params = { customers: Customer.active.take(3).map(&:id), message: 'Pay attention to our holiday plan.', subject: 'Holiday Plan' }
    MyMailer.send_customers_email(params)
  end

  def mail_spot_quotes
    json = {
      customer_id:"987", port_id: 1, rail_road_id: ["1","2"],
      ssline_id: [], zip: "60417", dest_address: "Crete, IL 60417, USA",
      container_size_id: 2, container_type_id: 5, cargo_weight: [1],
      drop_pull: true, live_load: true, hazardous: 0,
      email_to: "tueusut@gmail.com",
      comment: "",
      rail_miles: { "1" => "52256", "2" => "47901" },
      http_user_agent: "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_11_3) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/48.0.2564.109 Safari/537.36",
      who: 335,
      send_quote: true,
      bcc_quote: true
    }.to_json
    sqs = SpotQuote.first(5)
    sqs.map do |sq|
      sq.update_columns(free_text1: "fuel price is raised up a lot recently", q_free_text1: 20)
    end
    MyMailer.mail_spot_quotes(json, sqs.map(&:id))
  end

  def forward_sms_to_email
    trucker = Trucker.active.first
    params = {
      "From" => trucker.pure_mobile_phone,
      "Body" => "Thank you very much!",
      "MediaContentType0"=>"image/jpeg",
      "NumMedia"=>"1",
      "MediaUrl0"=>"http://api.twilio.com/2010-04-01/Accounts/AC0295e7c2428c6b19cf993747d4fd9b10/Messages/MM7e57ee2fa1854a8d9ec22f40547ec3a9/Media/ME0d10a48a984c6919a285488eca88bd63"
    }
    MyMailer.forward_sms_to_email(params)
  end

  def invalid_address
    MyMailer.invalid_address(Customer.active.sample)
  end

  def mobile_apps
    trucker = Trucker.active.first
    MyMailer.mobile_apps(trucker.id)
  end
end
