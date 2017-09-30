class MailerBase < ActionMailer::Base

  helper :application

  layout 'mail'

  default from: Proc.new{ SystemSetting.default.dispatch_email rescue '' },
          bcc: Proc.new{ SystemSetting.default.default_bcc_email rescue '' } # see override in config/initializers/action_mailer.rb

  # def self.init_default
  #   default_url_options[:host] = Owner.first.web_hostname rescue 'localhost'
  #   default_url_options[:protocol] = Owner.first.web_protocol rescue 'http'
  # end

  def sender_name_for(name)
    case name
    when :order_status
      "#{Rails.application.secrets.app} Order Status <#{SystemSetting.default.dispatch_email}>"
    else
    end
  end

  # init_default
end
