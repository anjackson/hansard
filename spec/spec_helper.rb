# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec/rails'
require 'spec/models/xml_generating_model_spec'
require 'spec/models/shared_contribution_spec'
require 'spec/controllers/date_based_controller_spec'

Spec::Runner.configure do |config|
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures'

  config.include Haml::Helpers
  config.include ActionView::Helpers

  config.before(:each, :behaviour_type => :helper) do
    @haml_is_haml = true
    @haml_stack = [Haml::Buffer.new(:attr_wrapper => "'")]
  end
  
  # You can declare fixtures for each behaviour like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so here, like so ...
  #
  #   config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
end
