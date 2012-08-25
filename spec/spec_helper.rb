# This file is copied to ~/spec when you run 'ruby script/generate rspec'
# from the project root directory.
ENV["RAILS_ENV"] = "test"
require File.expand_path(File.dirname(__FILE__) + "/../config/environment")
require 'spec'
require 'spec/rails'

shared_specs = ['models/xml_generating_model_spec',
                'models/shared_contribution_spec',
                'models/shared_mentionable_spec',
                'models/shared_json_renderer_spec',
                'models/shared_written_body_spec',
                'controllers/date_based_controller_spec',
                'controllers/house_controller_spec_helper',
                'controllers/abstract_controller_spec_helper',
                'lib/hansard/hansard_parser_spec_helper']
                  
shared_specs.each do |shared_spec|  
  require File.expand_path(File.dirname(__FILE__) + "/../spec/#{shared_spec}")
end

def data_file_path filename
  path = File.join(RAILS_ROOT,'spec','data', filename)
end


# specs need to be able to run independently of solr
module ActsAsSolr
  module ActsMethods
    def acts_as_solr(options)
    end
  end
end

Spec::Runner.configure do |config|
  # If you're not using ActiveRecord you should remove these
  # lines, delete config/database.yml and disable :active_record
  # in your config/boot.rb
  config.use_transactional_fixtures = true
  config.use_instantiated_fixtures  = false
  config.fixture_path = RAILS_ROOT + '/spec/fixtures/'

  config.before(:suite) do 
    Sitting.delete_all
    Section.delete_all
    Division.delete_all
    Vote.delete_all
    Contribution.delete_all
  end
  # == Fixtures
  #
  # You can declare fixtures for each example_group like this:
  #   describe "...." do
  #     fixtures :table_a, :table_b
  #
  # Alternatively, if you prefer to declare them only once, you can
  # do so right here. Just uncomment the next line and replace the fixture
  # names with your fixtures.
  #
  # config.global_fixtures = :table_a, :table_b
  #
  # If you declare global fixtures, be aware that they will be declared
  # for all of your examples, even those that don't use them.
  #
  # You can also declare which fixtures to use (for example fixtures for test/fixtures):
  #
  # config.fixture_path = RAILS_ROOT + '/spec/fixtures/'
  #
  # == Mock Framework
  #
  # RSpec uses it's own mocking framework by default. If you prefer to
  # use mocha, flexmock or RR, uncomment the appropriate line:
  #
  # config.mock_with :mocha
  # config.mock_with :flexmock
  # config.mock_with :rr
  #
  # == Notes
  # 
  # For more information take a look at Spec::Example::Configuration and Spec::Runner
  
  config.before(:each, :behaviour_type => :helper) do    
    config.include Haml::Helpers
    config.include ActionView::Helpers
    init_haml_helpers
  end
  
end
