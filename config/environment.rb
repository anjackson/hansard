# Be sure to restart your web server when you modify this file.

# Uncomment below to force Rails into production mode when
# you don't control web/app server and can't set it the proper way
# ENV['RAILS_ENV'] ||= 'production'

# Specifies gem version of Rails to use when vendor/rails is not present
RAILS_GEM_VERSION = '1.2.3' unless defined? RAILS_GEM_VERSION

# Bootstrap the Rails environment, frameworks, and default configuration
require File.join(File.dirname(__FILE__), 'boot')

Rails::Initializer.run do |config|
  # Settings in config/environments/* take precedence over those specified here

  # Skip frameworks you're not going to use (only works if using vendor/rails)
  # config.frameworks -= [ :active_resource, :action_mailer ]

  # Only load the plugins named here, by default all plugins in vendor/plugins are loaded
  # config.plugins = %W( exception_notification ssl_requirement )

  # Add additional load paths for your own custom dirs
  # config.load_paths += %W( #{RAILS_ROOT}/extras )

  # Force all environments to use the same logger level
  # (by default production uses :info, the others :debug)
  # config.log_level = :debug

  # Your secret key for verifying cookie session data integrity.
  # If you change this key, all old sessions will become invalid!
  config.action_controller.session = {
    :session_key => '_hansard_session',
    :secret      => '75aba46bfb4d6d8de2c59184ac72ca81'
  }

  # Use the database for sessions instead of the file system
  # (create the session table with 'rake db:sessions:create')
  # config.action_controller.session_store = :active_record_store

  # Use SQL instead of Active Record's schema dumper when creating the test database.
  # This is necessary if your schema can't be completely dumped by the schema dumper,
  # like if you have constraints or database-specific column types
  # config.active_record.schema_format = :sql

  # Activate observers that should always be running
  # config.active_record.observers = :cacher, :garbage_collector

  # Make Active Record use UTC-base instead of local time
  # config.active_record.default_timezone = :utc

  # See Rails::Configuration for more options

  # Application configuration should go into files in config/initializers
  # -- all .rb files in that directory is automatically loaded
end

require 'htmlentities'
require 'lib/acts_as_hansard_element'
require 'lib/acts_as_slugged'
require 'lib/in_groups_by'
require 'lib/roman_numerial_converter'

ActiveRecord::Base.send(:include, Acts::HansardElement)
ActiveRecord::Base.send(:include, Acts::Slugged)

PRODUCTION_HOST = "rua.parliament.uk"
SEARCH_HOST     = "10.100.10.76"
MAIL_HOST       = "hp3k13m.parliament.uk"

# General mail settings
ActionMailer::Base.delivery_method = :smtp
ActionMailer::Base.raise_delivery_errors = true
ActionMailer::Base.smtp_settings = {:address => MAIL_HOST,
                                    :port => "25",
                                    :domain => PRODUCTION_HOST}

APPLICATION_URLS = {:search    => "http://#{SEARCH_HOST}/search"}

# Settings for the exception notification plugin
ExceptionNotifier.exception_recipients = %w(brookr@parliament.uk)
ExceptionNotifier.sender_address = %("Prototype Error" <brookr@parliament.uk>)
ExceptionNotifier.email_prefix = "[Historical Hansard] "

# Setting for Google Custom Search
GOOGLE_CUSTOM_SEARCH_URL_STEM = "http://www.google.com/search?cx=009235156257972297288%3Ac3zploqlzek&client=google-csbe&output=xml_no_dtd&q="