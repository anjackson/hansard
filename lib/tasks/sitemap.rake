namespace :hansard do

  parse_processes.times do |index|
    task "call_sitting_sitemaps_#{index}".to_sym => [:environment] do 
      command = "rake RAILS_ENV=#{ENV['RAILS_ENV']} hansard:sitting_sitemaps[#{parse_processes},#{index}]"
      run_in_shell(command, index)
    end
     
    multitask :all_sitting_sitemaps => ["hansard:call_sitting_sitemaps_#{index}"] 
  end
  
  desc 'Loads source files in one process of many'
  task :sitting_sitemaps, :total_processes, :process_index, :needs => [:environment] do |t, args|
    SittingSiteMap.make_sitting_sitemaps(args.total_processes.to_i, args.process_index.to_i, ENV['HOST'], $stdout)
  end
  
  desc 'clear sitemaps'
  task :clear_sitemaps => [:environment] do 
    unless ENV['HOST']
      puts ''
      puts 'usage: rake hansard:clear_sitemaps HOST=hostname'
      puts ''
      exit 0
    end
    sitemap_index = SiteMapIndex.new(ENV['HOST'], $stdout)
    sitemap_index.clear_sitemaps
  end
  
  desc 'make xml sitemap files'
  task :make_sitemap => [:environment, :clear_sitemaps, :all_sitting_sitemaps] do
    unless ENV['HOST']
      puts ''
      puts 'usage: rake hansard:make_sitemap HOST=hostname'
      puts ''
      exit 0
    end
    sitemap_index = SiteMapIndex.new(ENV['HOST'], $stdout)
    sitemap_index.write_to_file!
  end

end
