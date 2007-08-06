require File.join(File.dirname(__FILE__),'..','deconstruct.rb')

namespace :hansard do

  task :migrate_down do
    log = `rake db:migrate VERSION=0`
    puts log
  end
  
  task :migrate_up => [:environment] do
    Rake::Task['db:migrate'].invoke
  end

  task :clone_structure do
    Rake::Task['db:test:clone_structure'].invoke
  end

  desc 'migrates db down and up, does db:test:clone_structure, and runs rake spec'
  task :clean_sweep => [:migrate_down, :migrate_up, :clone_structure] do
    Rake::Task[:spec].invoke
  end

end
