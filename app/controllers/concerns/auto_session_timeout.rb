module AutoSessionTimeout
  extend ActiveSupport::Concern

  module ClassMethods

  	def auto_session_timeout(seconds)
      return if Rails.env.development?
  		prepend_before_action do |c|
        if c.session[:expiry_time]&&(c.session[:expiry_time] < Time.now)
          c.send(:reset_session)
        else
          c.session[:expiry_time] = Time.now + seconds
        end
  		end
  	end
	end
end
