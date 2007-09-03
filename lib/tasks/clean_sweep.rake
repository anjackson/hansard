namespace :hansard do

  task :migrate_down => :environment do
    ENV['VERSION'] = '0'
    Rake::Task['db:migrate'].execute
  end

  task :migrate_up => :environment do
    ENV.delete('VERSION')
    Rake::Task['db:migrate'].execute
  end

  task :clone_structure do
    Rake::Task['db:test:clone_structure'].invoke
  end

  desc 'migrates db down and up, does db:test:clone_structure, and runs rake spec'
  task :clean_sweep => [:migrate_down, :migrate_up, :clone_structure] do
  end

end
