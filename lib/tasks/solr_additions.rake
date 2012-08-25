namespace :solr do

  desc 'switches off solr indexing'
  task :disable_save => :environment do
    # Disable solr_optimize
    module ActsAsSolr #:nodoc:
      module InstanceMethods
        def blank() end
        alias_method :original_solr_save, :solr_save
        alias_method :solr_save, :blank
        alias_method :original_solr_destroy, :solr_destroy
        alias_method :solr_destroy, :blank
      end
    end#module ActsAsSolr
  end

  desc 'switches on solr indexing (only to be used after solr:disable)'
  task :enable_save => :environment do
    # Disable solr_optimize
    module ActsAsSolr #:nodoc:
      module InstanceMethods
        alias_method :solr_save, :original_solr_save
        alias_method :solr_destroy, :original_solr_destroy
      end
    end#module ActsAsSolr
  end

  desc 'Adds contributions to the solr index'
  task :add_contributions => :environment do

    offset       = ENV['OFFSET'].to_i.nonzero? || 0
    upto         = ENV['UPTO'].to_i.nonzero? || 0
    verbose      = env_to_bool('VERBOSE',     false)
    batch_size   = ENV['BATCH'].to_i.nonzero? || 300

    puts "About to rebuild index for Contributions"
    Contribution.rebuild_solr_index(batch_size, upto, {:offset => offset, :verbose => verbose}){ |ar, options| ar.find(:all, :include => {:section => :sitting}, :conditions => ["contributions.id > ? and contributions.id <= ?", options[:offset], options[:limit] + options[:offset]])}
  end
  
  parse_processes.times do |index|
    task "index_contributions_chunk_#{index}".to_sym => :environment do 
       verbose      = env_to_bool('VERBOSE',     false)
       batch_size   = ENV['BATCH'].to_i.nonzero? || 300
       batch_limit  = batch_size * 100
       limit        = (@max_id / parse_processes ) * (index+1)
       offset       = ENV['OFFSET'].to_i.nonzero? || ((@max_id / parse_processes ) * index)
       batch_limit  = limit-offset if limit-offset < batch_limit
       shell = Session::Shell.new
       begin
         command = "rake RAILS_ENV=#{ENV['RAILS_ENV']} solr:add_contributions OFFSET=#{offset} UPTO=#{offset+batch_limit} VERBOSE=#{verbose} BATCH=#{batch_size} --trace"
         shell.outproc = lambda{ |out| puts "process-#{index}: #{ out }" }
         shell.errproc = lambda{ |err| puts "process-#{index}: #{ err }" }
         puts "process-#{index}: #{command}"
         shell.execute(command) 
         offset += batch_limit
       end while limit > offset
     end
     
    multitask :reindex_contributions => ["solr:index_contributions_chunk_#{index}"] 
  end

  desc %{Reindexes data for contributions. Clears index first to get rid of orphaned records and optimizes index afterwards. RAILS_ENV=your_env to set environment. START_SERVER=true to solr:start before and solr:stop after. BATCH=123 to post/commit in batches of that size: default is 300. CLEAR=false to not clear the index first; OPTIMIZE=false to not optimize the index afterwards.}
  task :reindex => :environment do
    
    start_server = env_to_bool('START_SERVER', false)
    clear_first  = env_to_bool('CLEAR',       true)

    start_time = Time.now
    
    if start_server
      puts "About to start Solr server"
      Rake::Task["solr:start"].invoke
      puts "Started Solr server"
    end

    if clear_first
      puts "About to clear index for Contributions"
      ActsAsSolr::Post.execute(Solr::Request::Delete.new(:query => "id:[* TO *]"))
      puts "Cleared index for Contributions"
    end
    
    @max_id = Contribution.count_by_sql("select max(id) as id from contributions")
    @min_id = Contribution.count_by_sql("select min(id) as id from contributions")
    
    Rake::Task['solr:reindex_contributions'].invoke

    begin
      puts "About to optimise Contributions"
      Contribution.solr_optimize
      puts "Optimised Contributions"
    rescue Timeout::Error
      puts "Timed out whilst trying to optimise Contributions"
    end
    
    puts "Time taken: #{Time.now - start_time}"


    if start_server
      puts "About to stop Solr"
      Rake::Task["solr:stop"].invoke
      puts "Stopped Solr"
    end

  end

  def env_array_to_constants(env)
    env = ENV[env] || ''
    env.split(/\s*,\s*/).map { |m| m.singularize.camelize.constantize }.uniq
  end

  def env_to_bool(env, default)
    env = ENV[env] || ''
    case env
      when /^true$/i: true
      when /^false$/i: false
      else default
    end
  end

end