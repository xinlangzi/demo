source 'https://rubygems.org'

git_source(:github) do |repo_name|
  repo_name = "#{repo_name}/#{repo_name}" unless repo_name.include?("/")
  "https://github.com/#{repo_name}.git"
end

ruby '2.4.1'
gem 'appengine', '~> 0.4.3'
gem 'rails', '5.1.4'
gem 'rails-observers', github: 'rails/rails-observers'
gem 'jbuilder', '~> 2.5'
gem 'net-sftp'
gem 'request_store'
gem 'pundit' #authorization
gem 'paper_trail'
gem 'puma', '~> 3.7'
# # database
gem 'mysql2', '>= 0.3.18', '< 0.5'
# # template respond
gem 'responders'
# # template
gem 'slim-rails'
# # Detect browser
gem 'browser'
# # quick search
gem 'ransack'
# , github:"activerecord-hackery/ransack"
# # pagination
gem 'kaminari'
# # ancestry association
gem 'ancestry'
# # xml parse
gem 'nokogiri'
# # output print
gem 'awesome_print'
# # switch user
gem 'switch_user'
gem 'settingslogic'
gem 'googlecharts'
gem 'twilio-ruby'
# gem 'incurve'
gem 'friendly_id'
# # file upload
gem 'dropzonejs-rails'
gem 'carrierwave', '~> 1.0'
gem 'fog-aws'
gem 'mini_magick'
# # inline css email
gem 'premailer-rails'
# # PDF generator
gem 'prawn'
# gem 'wisepdf'
gem 'combine_pdf'
# # render
gem 'render_anywhere', '0.0.9', require: false
gem 'render_async'
# # seed data
gem 'seed-fu'
# # used in module payable
gem 'linguistics'
# # validate datetime
gem 'validates_timeliness'
# # taggable
gem 'acts-as-taggable-on', '~> 4.0'
gem "paranoia", "~> 2.2"
gem 'docusign_rest'

#delay job
gem 'sidekiq', '< 5'
gem 'sidekiq-limit_fetch'
gem 'sinatra', github: 'sinatra', require: false # just for sidekiq

# manage Procfile
gem 'foreman'
gem 'redis-rails'
gem 'redis-namespace'
# gem 'multi_fetch_fragments'
# Quickbook
gem 'riif', github: 'pracstrat/riif'

# # Assets: css & javascript
gem 'bootstrap', '4.0.0.alpha6'
gem 'uglifier', '>= 1.3.0'
gem 'sass-rails', '~> 5.0'
gem 'coffee-rails', '~> 4.2'
gem 'compass-rails'
gem 'font-awesome-rails'
gem 'turbolinks', '~> 5'
gem 'jquery-rails'
gem 'jquery-ui-rails'
gem 'jquery-datatables-rails'
gem 'jquery-multiselect-rails', github: 'arojoal/jquery-multiselect-rails'
gem 'rails3-jquery-autocomplete'
gem 'chosen-rails'
gem 'elevatezoom-rails'
gem 'whenever'
gem 'simple_form'
gem 'nested_form'
gem 'cocoon' # new plugin to replace nested_form; Search link_to_add
gem 'facebox-rails', github: 'pracstrat/facebox-rails'
gem 'jstree-rails-4'
gem 'momentjs-rails'
gem 'fullcalendar-rails'
gem 'geocomplete_rails'
# Data-Driven Documents graphic report
gem 'novus-nvd3-rails'

### Mobile
gem 'framework7_rails'
gem 'ionicons-rails'
### Native Mobile
gem 'rack-cors', :require => 'rack/cors'

# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 3.0'
# Use ActiveModel has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Capistrano for deployment
# gem 'capistrano-rails', group: :development

group :development, :test do
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: [:mri, :mingw, :x64_mingw]
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '~> 2.13'
  gem 'selenium-webdriver'
end

group :development do
  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.
  gem 'web-console', '>= 3.3.0'
  gem 'listen', '>= 3.0.5', '< 3.2'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
  gem 'spring-watcher-listen', '~> 2.0.0'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: [:mingw, :mswin, :x64_mingw, :jruby]
