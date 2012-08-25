require File.dirname(__FILE__) + '/../task_helper'
namespace :commons_library do
  
  include TaskHelper
  
  def get_commons_library_data_source
    commons_data_source = DataSource.find_by_name("Commons Library")
    raise "Couldn't find 'Commons Library' data source" unless commons_data_source
    commons_data_source
  end
  
  desc 'Populate lords memberships from reference data sql file' 
  task :populate_lords_memberships => :environment do 
    populate_table_from_sql_file('LordsMembership', 'commons_library_data')
  end
  
  desc 'Populate Lords memberships from file'
  task :populate_lords_memberships_from_file => :environment do 
    commons_library_data_source = get_commons_library_data_source
    load_lords_memberships_from_file('lords_memberships.txt', 'commons_library_data', commons_library_data_source)
  end
  
  desc 'Populate alternative names from reference data sql file'
  task :populate_alternative_names => :environment do 
    populate_table_from_sql_file('AlternativeName', 'commons_library_data')
  end
  
  desc 'Populate alternative names from reference data text file'
  task :populate_alternative_names_from_file => :environment do 
    commons_library_data_source = get_commons_library_data_source
    load_alternative_names_from_file('alternative_names.txt', 'commons_library_data', commons_library_data_source)
  end
  
  desc 'Populate alternative titles from reference data sql file'
  task :populate_alternative_titles => :environment do 
    populate_table_from_sql_file('AlternativeTitle', 'commons_library_data')
  end
  
  desc 'Populate alternative titles from reference data text file'
  task :populate_alternative_titles_from_file => :environment do 
    commons_library_data_source = get_commons_library_data_source
    load_alternative_titles_from_file('alternative_titles.txt', 'commons_library_data', commons_library_data_source)
  end
  
  desc 'Populate constituencies data from sql dump in reference data'
  task :populate_constituencies => :environment do 
    populate_table_from_sql_file('Constituency', 'commons_library_data')
  end
  
  desc 'Populate acts data from sql dump in reference data'
  task :populate_acts => :environment do 
    populate_table_from_sql_file('Act', 'commons_library_data')
  end
  
  desc 'Populate bills data from sql dump in reference data'
  task :populate_bills => :environment do 
    populate_table_from_sql_file('Bill', 'commons_library_data')
  end
  
  desc 'Populate parties data from sql dump in reference data'
  task :populate_parties => :environment do 
    populate_table_from_sql_file('Party', 'commons_library_data')
  end
  
  desc 'Populate people from reference data text file'
  task :populate_people_from_file => :environment do 
    load_people_from_file('people.txt', 'commons_library_data', get_commons_library_data_source)
  end
  
  desc 'Populate people from reference data sql file' 
  task :populate_people => :environment do 
    populate_table_from_sql_file('Person', 'commons_library_data')
  end
  
  desc 'Populate constituencies from reference data text file'
  task :populate_constituencies_from_file => :environment do 
    load_constituencies_from_file('constituencies.txt', 'commons_library_data', get_commons_library_data_source)
  end
  
  desc 'Populate office holders from reference data text file' 
  task :populate_office_holders_from_file => :environment do 
    load_office_holders_from_file 'office_holders.txt', 'commons_library_data', get_commons_library_data_source
  end
  
  desc 'Populate offices from reference data sql file'
  task :populate_office_holders => :environment do 
    populate_table_from_sql_file('OfficeHolder', 'commons_library_data')
  end
  
  desc 'Populate commons memberships from reference data sql file' 
  task :populate_commons_memberships => :environment do 
    populate_table_from_sql_file('CommonsMembership', 'commons_library_data')
  end
  
  
  desc 'Populate commons memberships from reference data text file' 
  task :populate_commons_memberships_from_file => :environment do 
    load_commons_memberships_from_file('commons_memberships.txt', 'commons_library_data', get_commons_library_data_source)
  end
  
  desc 'Populate parliament sessions from reference data text file'
  task :populate_parliament_sessions_from_file => :environment do 
    puts "Loading parliament session data from file"
    load_parliament_sessions_from_file('parliament_sessions.txt', 'commons_library_data', get_commons_library_data_source)
  end
  
  desc 'Populate constituency aliases from mysql dump file'
  task :populate_constituency_aliases => :environment do 
    populate_table_from_sql_file('ConstituencyAlias', 'commons_library_data')
  end
  
  desc 'Populate constituency aliases from reference data text file'
  task :populate_constituency_aliases_from_file => :environment do 
    File.new("#{RAILS_ROOT}/reference_data/commons_library_data/constituency_aliases.txt").each do |line|
      attributes = parse_constituency_aliases_line(line)
      import_id = attributes.delete(:import_id)
      start_date = attributes[:start_date]
      constituencies = Constituency.find(:all, :conditions => ["import_id = ?", import_id])
      raise "No constituency found for import_id #{import_id}" if constituencies.empty?
      raise "Multiple constituencies found for import_id #{import_id}" if constituencies.size > 1
      constituency = constituencies.first
      attributes[:constituency_id] = constituency.id
      ConstituencyAlias.create(attributes)
    end
  end
  
  def parse_constituency_aliases_line line
    d = line.split("\t")
    atts = { :alias               => d[0],
             :import_id           => d[1],
             :start_date          => Date.parse(d[2]),
             :end_date            => Date.parse(d[3])
           }
  end
end
