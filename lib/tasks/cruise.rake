rspec_base = File.expand_path("#{RAILS_ROOT}/vendor/plugins/rspec/lib")
$LOAD_PATH.unshift(rspec_base) if File.exist?(rspec_base)
require 'spec/rake/spectask'
require 'spec/rake/verify_rcov'


namespace :db do
  namespace :test do
    desc 'Use the migrations to create the test database'
    task :migrate_schema => 'db:test:purge' do
      ActiveRecord::Base.establish_connection(ActiveRecord::Base.configurations['test'])
      ActiveRecord::Migrator.migrate("db/migrate/")
    end
  end
end

desc 'Cruise default task - update the environment and run the tests with rcov'
task :cruise do
  ENV['RAILS_ENV'] = RAILS_ENV = 'test'
  Rake::Task['db:migrate'].invoke
  Rake::Task['cruise_coverage'].invoke
end

desc "Run specs and rcov"
Spec::Rake::SpecTask.new(:cruise_coverage) do |t|
  
  t.spec_opts = ['--options', "#{RAILS_ROOT}/spec/rcov_spec.opts"]
  t.spec_files = FileList['spec/**/*_spec.rb']
  t.rcov = true
  t.rcov_dir = ENV['CC_BUILD_ARTIFACTS']
  t.rcov_opts = ['--exclude', 'spec,/usr/lib/ruby', '--rails', '--text-report', '-Ilib']
end
