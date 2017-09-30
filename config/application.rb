require_relative 'boot'

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Demo
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.1

    config.middleware.use Rack::Cors do
      allow do
        origins '*'
        resource '*', headers: :any, methods: [:get, :post, :options]
      end
    end

    config.autoload_paths += %w(
      app/models/filters
      app/models/categories
      app/models/containers
      app/models/mobile
    )

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration should go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded.
  end
end
EMAIL= '[a-z0-9][_a-z0-9-]*(\.[_a-z0-9-]+)*@[a-z0-9][a-z0-9-]*(\.[a-z0-9-]+)*(\.[a-z]{2,})'
REGEX_EMAIL_VALIDATOR = /\A\s*((#{EMAIL}(\s*,\s*))*(#{EMAIL})?\s*)?\s*\Z/i
# This one taken from http://api.rubyonrails.org/classes/ActiveModel/Validations/ClassMethods.html#method-i-validates
EMAIL_REGEX = %r{^([^@\s]+)@((?:[-a-zA-Z0-9]+\.)+[[:alpha:]]{2,})$}
ABSTRACT_CLASS_INST_ERROR = "You can not have an object of the base class, %s"
PLEASE_WAIT = "Please wait..."
EMAIL_FORMAT_TIP = 'Accepts comma separated (,) multiple email addresses, e.g. "one@example.com,two@example.com"'
EMAIL_FORMAT_TIP_WITH_BR = 'Accepts comma separated (,) multiple email addresses, <br/>e.g. "one@example.com,two@example.com"'
METER_TO_MILE = 1609.344
ANDROID_APP_URL = "https://play.google.com/store/apps/details?id=com.practicalstrategies.tz"
IOS_APP_URL = "https://itunes.apple.com/us/app/truckerzoom-mobile/id1270330586?mt=8"
