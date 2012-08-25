require File.dirname(__FILE__) + '/../hansard/parser_task_helper'
require File.dirname(__FILE__) + '/../task_helper'
require File.dirname(__FILE__) + '/../hansard/schema_validator'

namespace :hansard do

  include TaskHelper
  include Hansard::ParserTaskHelper
  include Hansard::SchemaValidator

  TIMINGS = []

  def parse_processes
    if ['production', 'hot'].include? ENV['RAILS_ENV'] 
      4
    else
      4
    end
  end
  
  desc 'attempts to validate XML source file against schema'
  task :validate_schema => :environment do
    validate_schema
  end

  task :migrate_down => :environment do
    ENV['VERSION'] = '0'
    puts 'About to migrate down to VERSION=0'
    Rake::Task['db:migrate'].execute('param needed for rake 0.8.1')
    puts 'Migrated down to VERSION=0'
  end

  task :migrate_up => :environment do
    ENV.delete('VERSION')
    puts 'About to migrate up to latest VERSION'
    Rake::Task['db:migrate'].execute('param needed for rake 0.8.1')
    puts 'Migrated up to latest VERSION'
  end

  task :clone_structure do
    puts 'About to clone structure to test database'
    Rake::Task['db:test:clone_structure'].invoke
    puts 'Cloned structure to test database'
  end

  desc 'migrates db down and up, does db:test:clone_structure, and runs rake spec'
  task :clean => [:migrate_down, :migrate_up, :clone_structure] do
  end

  task :recreate_dev_db do
    `sudo mysqladmin drop -f hansard_development`
    `sudo mysqladmin create hansard_development`
    `sudo mysql hansard_development < db/development_structure.sql`
  end

  require 'ruby-prof'

  task :start_profiler do
    puts ENV['profile'] ? "Profiling is ON" : "Profiling is OFF"
    if ENV['profile']
      RubyProf.start
    end
  end

  def print_profiler_report printer, result, options=0
    timestamp = DateTime.now.to_s.sub('T','_').gsub(':','-').split('+').first
    filename = "#{timestamp}_#{printer.name.split('::').last.downcase}.txt"
    Dir.mkdir('profiler') unless File.exists?('profiler')

    p result.inspect
    File.open("profiler/#{filename}", 'w') do |file|
      printer.new(result).print(file, options)
    end
  end

  task :stop_profiler do
    p ENV['profile']
    if ENV['profile']
      result = RubyProf.stop
      print_profiler_report RubyProf::GraphPrinter, result
      print_profiler_report RubyProf::FlatPrinter, result
      print_profiler_report RubyProf::CallTreePrinter, result, {}
    end
  end

  desc 'does a clean sweep and loads xml, reindexes with solr'
  task :regenerate => [:migrate_down,
                       :migrate_up,
                       :populate,
                       :start_profiler,
                       :load_new,
                       :stop_profiler,
                       :clone_structure] do
    puts 'Regenerated all data'
    puts ''
    
    # [Act,Bill].each do |model|
      # puts "populating #{model.name} mentions took: #{model.inner_timing}"
      # puts ''
    # end
  end
  
  task :timed_regenerate do 
    start_time = Time.now
    Rake::Task["hansard:regenerate"].invoke
    TIMINGS << "Total run took: #{(Time.now - start_time).to_s}"
    TIMINGS.each {|t| puts t; puts ''}
  end

  desc 'populates data (including people) from reference data'
  task :populate => [:environment, 
                     :populate_data_sources,
                     :populate_series,
                     "hop:populate_constituencies",
                     "hop:populate_people",
                     "hop:populate_commons_memberships",
                     "hop:populate_lords_memberships",
                     "hop:populate_elections",
                     "hop:populate_offices",
                     "hop:populate_office_holders",
                     "hop:populate_alternative_names",
                     "commons_library:populate_constituencies",
                     "commons_library:populate_constituency_aliases",
                     "commons_library:populate_people",
                     "commons_library:populate_commons_memberships",
                     "commons_library:populate_lords_memberships",
                     "commons_library:populate_office_holders",
                     "commons_library:populate_alternative_names",
                     "commons_library:populate_alternative_titles",
                     "commons_library:populate_acts", 
                     "commons_library:populate_bills",
                     "commons_library:populate_parties"
                     ] do
  end
  
  desc 'recreate History of Parliament Trust reference data sql files'
  task :recreate_hop_sql_files => [:environment, 
                                   :migrate_down,
                                   :migrate_up, 
                                   :populate_data_sources,
                                   :populate_series,
                                   "hop:populate_constituencies_from_file",
                                   "hop:populate_people_from_file",
                                   "hop:populate_commons_memberships_from_file",
                                   "hop:populate_lords_memberships_from_file",
                                   "hop:populate_elections",
                                   "hop:populate_offices_from_file",
                                   "hop:populate_office_holders_from_file",
                                   "hop:populate_alternative_names_from_file"] do 
    ['Constituency', 'Person', 'CommonsMembership', 'LordsMembership', 'Office', 'OfficeHolder', 'AlternativeName'].each do |name|
      dump_table_to_sql_file(name, 'hop_data')  
    end
  end
  
  desc 'recreate Commons Library reference data sql files'
  task :recreate_commons_library_sql_files => [:environment, 
                                               :recreate_hop_sql_files,
                                               "commons_library:populate_constituencies_from_file",
                                               "commons_library:populate_constituency_aliases_from_file",
                                               "commons_library:populate_people_from_file",
                                               "commons_library:populate_commons_memberships_from_file",
                                               "commons_library:populate_lords_memberships_from_file",
                                               "commons_library:populate_office_holders_from_file",
                                               "commons_library:populate_alternative_names_from_file",
                                               "commons_library:populate_alternative_titles_from_file"
                                               ] do 
    ['Constituency', 'ConstituencyAlias', 'Person', 'CommonsMembership', 'LordsMembership', 'OfficeHolder', 'AlternativeName', 'AlternativeTitle'].each do |name|
      dump_table_to_sql_file(name, 'commons_library_data')  
    end
  end

  def run_in_shell(command, index)
     shell = Session::Shell.new
     shell.outproc = lambda{ |out| puts "process-#{index}: #{ out }" }
     shell.errproc = lambda{ |err| puts err }
     puts "Starting process #{index}, total processes: #{parse_processes}"
     puts command
     shell.execute(command)
  end
  
  parse_processes.times do |index|
    task "call_load_data_#{index}".to_sym => [:environment] do 
       start_time = Time.now
       command = "rake RAILS_ENV=#{ENV['RAILS_ENV']} hansard:load_data[#{parse_processes},#{index}]"
       run_in_shell(command, index)
       TIMINGS << "call_load_data_#{index} took: #{(Time.now - start_time).to_s}" 
     end
     
    multitask :load_series => ["hansard:call_load_data_#{index}"] 
  end
  
  def data_load total_processes, process_index
    @splitter = Hansard::Splitter.new((overwrite=true), true)
    per_source_file total_processes, process_index do |file|
      source_file  = split_file file
      if source_file.result_directory
        load_split_files source_file
      end
    end
  end
  
  desc 'Loads source files in one process of many'
  task :load_data, :total_processes, :process_index, :needs => [:environment, "solr:disable_save"] do |t, args|
    data_load(args.total_processes.to_i, args.process_index.to_i)
  end
  
  task :cleanup_unused_reference_data => [:environment, 'solr:disable_save'] do 
                                     
    Act.connection.execute('DELETE acts.*
                            FROM acts
                            LEFT JOIN act_mentions
                            ON act_mentions.act_id = acts.id
                            WHERE act_mentions.act_id is null')
    
    Bill.connection.execute('DELETE bills.*
                             FROM bills
                             LEFT JOIN bill_mentions
                             ON bill_mentions.bill_id = bills.id
                             WHERE bill_mentions.bill_id is null')      
    process_people do |person|
      person.contribution_count = person.calculate_contribution_count
      person.membership_count = person.calculate_membership_count
      person.save!
    end
    
    process_acts do |act|
      act.act_mentions_count = act.mentions.count
      act.save!
    end
    
    process_bills do |bill|
      bill.bill_mentions_count = bill.mentions.count
      bill.save!
    end
  
  end
  
  desc 'splits files in /xml, loads anything not loaded, reindexes with solr'
  task :load_new => [:environment, "solr:disable_save", :load_series] do
    start_time = Time.now
    Rake::Task["hansard:redact"].invoke
    Rake::Task["commons_library:populate_parliament_sessions_from_file"].invoke
    Rake::Task['hansard:cleanup_unused_reference_data'].invoke
    Rake::Task['hansard:match_divisions_to_bills'].invoke
    ParserRun.create!
    TIMINGS << "load_new took: #{(Time.now - start_time).to_s}"

    start_time = Time.now
    Rake::Task["solr:enable_save"].invoke
    puts 'Solr: save enabled'
    Rake::Task["solr:start"].invoke
    puts 'Solr: started'
    Rake::Task['solr:reindex'].invoke
    puts 'Solr: reindexed'
    TIMINGS << "solr:reindex took: #{(Time.now - start_time).to_s}"
  end

  desc 'wipes and reloads commons data from /data (doesn\'t re-split)'
  task :reload_commons => [:environment] do
    HouseOfCommonsSitting.destroy_all
    DataFile.delete(:conditions => "name like 'housecommons%'")
    Rake::Task['hansard:load_new_commons'].invoke
  end

  desc 'wipes and reloads commons data from /data for given date=yyyy-mm-dd (doesn\'t re-split)'
  task :reload_commons_on_date => [:environment] do
    if ENV['date']
      reload_commons_on_date Date.parse(ENV['date'])
    else
      puts ''; puts 'usage: rake hansard:reload_commons_on_date date=yyyy-mm-dd'; puts ''
    end
  end

  desc 'wipes and reloads lords data from /data (doesn\'t re-split)'
  task :reload_lords => [:environment] do
    HouseOfLordsSitting.destroy_all
    DataFile.delete(:conditions => "name like 'houselords%'")
    Rake::Task['hansard:load_new_lords'].invoke
  end

  desc 'wipes and reloads lords data from /data for given date=yyyy-mm-dd (doesn\'t re-split)'
  task :reload_lords_on_date => [:environment] do
    if ENV['date']
      reload_lords_on_date Date.parse(ENV['date'])
    else
      puts ''; puts 'usage: rake hansard:reload_lords_on_date date=yyyy-mm-dd'; puts ''
    end
  end

  desc 'wipes and reloads written answer data from /data (doesn\'t re-split)'
  task :reload_written => [:environment] do
    WrittenAnswersSitting.destroy_all
    DataFile.delete(:conditions => "name like '%writtenanswers%'")
    Rake::Task['hansard:load_new_written'].invoke
  end

  desc 'wipes and reloads written answers data from /data for given date=yyyy-mm-dd (doesn\'t re-split)'
  task :reload_written_answers_on_date => [:environment] do
    if ENV['date']
      reload_written_answers_on_date Date.parse(ENV['date'])
    else
      puts ''; puts 'usage: rake hansard:reload_written_answers_on_date date=yyyy-mm-dd'; puts ''
    end
  end

  desc 'wipes and reloads written statements data from /data for given date=yyyy-mm-dd (doesn\'t re-split)'
  task :reload_written_statements_on_date => [:environment] do
    if ENV['date']
      reload_written_statements_on_date Date.parse(ENV['date'])
    else
      puts ''; puts 'usage: rake hansard:reload_written_statements_on_date date=yyyy-mm-dd'; puts ''
    end
  end

  desc 'loads any unloaded commons data from /data (doesn\'t re-split)'
  task :load_new_commons => [:environment] do
    reload_data_files(COMMONS_PATTERN, Hansard::CommonsParser)
  end

  desc 'loads any unloaded lords data from /data (doesn\'t re-split)'
  task :load_new_lords => [:environment] do
    reload_data_files(LORDS_PATTERN, Hansard::LordsParser)
  end
  
  desc 'loads any unloaded grand committee data from /data (doesn\'t re-split)'
  task :load_new_grand_committee => [:environment] do
    reload_data_files(GRAND_COMMITTEE_PATTERN, Hansard::GrandCommitteeReportParser)
  end

  desc 'loads any unloaded lords data from /data (doesn\'t re-split)'
  task :load_new_lords_statements => [:environment] do
    reload_data_files(LORDS_WRITTEN_STATEMENTS_PATTERN, Hansard::WrittenStatementsParser)
  end

  desc 'loads any unloaded written answer data from /data (doesn\'t re-split)'
  task :load_new_written => [:environment] do
    reload_data_files(WRITTEN_PATTERN, Hansard::WrittenAnswersParser)
    reload_data_files(COMMONS_WRITTEN_PATTERN, Hansard::WrittenAnswersParser)
    reload_data_files(LORDS_WRITTEN_PATTERN, Hansard::WrittenAnswersParser)
  end

  desc 'splits Hansard XML files in /xml in to XML sections in /data, overwrites /data'
  task :split_xml => :environment do
    splitter = Hansard::Splitter.new((overwrite=true), true)
    splitter.split File.join(File.dirname(__FILE__),'..','..')
    puts 'Split ' + __FILE__
  end

  desc 'splits Hansard XML files in /xml in to XML sections in /data, doesnt overwrite /data'
  task :split_new_xml => :environment do
    splitter = Hansard::Splitter.new((overwrite=false), true)
    splitter.split File.join(File.dirname(__FILE__),'..','..')
    puts 'Split ' + __FILE__
  end

  desc 'Matches divisions to bills' 
  task :match_divisions_to_bills => :environment do 
    process_divisions do |division|
      if title = division.section_title
        bill = Bill.find_from_text(title)
        if bill
          division.bill = bill
          division.save!
        end
      end
    end
  
  end
  
  desc 'Deletes the sitting days identified in /reference_data/redaction.txt'
  task :redact => [:environment, "solr:disable_save"] do
    File.new(File.dirname(__FILE__) + '/../../reference_data/redaction.txt').each do |line|
      d = line.split("\t")
      date = Date.parse(d[0])
      house = d[1].strip
      model_class = Sitting.uri_component_to_sitting_model(house)
      models = model_class.find_all_by_date(date)
      puts "read line : #{line}"
      if models and models.size == 1
        model = models.first
        puts "sitting id #{model.id}"
        puts "destroying #{model_class.name} instance for #{date.to_s}"
        delete_conditions = []
        Contribution.contributions_for_sitting(model).each do |contribution|
          delete_conditions << "\"#{contribution.solr_id}\""
        end
        delete_query = "id:(#{delete_conditions.join(' OR ')})"
        model.destroy
        # remove all the associated contributions from solr
        Contribution.solr_delete_by_query(delete_query)
        Contribution.solr_commit
      else
        if models.size > 1
          puts "More than one sitting found - nothing done"
          p models
        else
          puts "No sittings found - nothing done"
        end
      end
    end
    Rake::Task["solr:enable_save"].invoke
  end

  desc 'Populate database from reference_data/data_sources.txt file'
  task :populate_data_sources => :environment do
    File.new(File.dirname(__FILE__) + '/../../reference_data/data_sources.txt').each do |line|
      attributes = parse_data_source_line(line)
      DataSource.create!(attributes)
    end
  end

  def parse_data_source_line line
    d = line.split("\t")
    {:name => d[0].strip }
  end

  private

  desc 'Populate Hansard series from reference_data/series_and_volumes.txt file'
  task :populate_series => :environment do
    start_time = Time.now
    Series.destroy_all
    puts "Populating Hansard series from reference data"
    Series.transaction do
      File.new(File.dirname(__FILE__) + '/../../reference_data/series_and_volumes.txt').each do |line|
        attributes = parse_series_line(line)
        print '.'
        $stdout.flush
        series = Series.create(attributes)
      end
    end
    TIMINGS << "populate_series took: #{(Time.now - start_time).to_s}"
    puts ''
  end

  def parse_series_line line
    d = line.split("\t")
    atts = { :number  => d[0].strip,
             :last_volume => d[1].strip,
             :house => d[2].strip
           }
    atts
  end

  desc 'Create tarred gzipped files for each decade of data in the data directory'
  task :tar_data_dir => :environment do
    first_year = FIRST_DATE.first_of_decade.year
    last_year = LAST_DATE.last_of_decade.year
    years = (first_year..last_year)
    decades = years.to_a.in_groups_of(10).map{|decade| Date.new(decade.first).decade_string }

    decades.each do |decade|

      decade_pattern = "data/#{decade[0..2]}*"
      if ! Dir.glob("#{RAILS_ROOT}/#{decade_pattern}").empty?
        tar_name = "#{RAILS_ROOT}/data/data_dir_#{Time.now.strftime("%m_%d_%Y")}_#{decade}.tar"
        system "tar -chf #{tar_name} #{decade_pattern}"
        system "gzip #{tar_name}"
        system "rm -rf #{RAILS_ROOT}/#{decade_pattern}"
      end
    end
  end

end

desc "Migrate down and up, populate reference data, load new XML, clone db structure"
task :hansard => "hansard:timed_regenerate"
