require "net/https"
require "uri"

class MyTwilio

  def self.configured?
    [account_sid, auth_token].all?
  end

  def self.account_sid
    SystemSetting.default.try(:account_sid)
  end

  def self.auth_token
    SystemSetting.default.try(:auth_token)
  end

  def self.setup
    Twilio::REST::Client.new(account_sid, auth_token)
  end

  def self.follow_redirects(url, request_max=5)
    raise "Max number of redirects reached" if request_max <= 0
    uri = URI.parse(url)
    http = Net::HTTP.new(uri.host, uri.port)
    if uri.instance_of?(URI::HTTPS)
      http.use_ssl = true
      http.verify_mode = OpenSSL::SSL::VERIFY_NONE
    end
    request = Net::HTTP::Get.new(uri.request_uri)
    response = http.request(request)
    code = response.code.to_i
    case code
    when 200
      return response.body
    when 301..307
      follow_redirects(response["location"], request_max - 1)
    else
      raise "No handle for response code: #{code} URL: #{url}"
    end
  end

  def self.get_media(url)
    follow_redirects(url)
  end

end