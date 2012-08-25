require File.dirname(__FILE__) + '/../task_helper'
HOP_PATH = '/../../reference_data/history_of_parliament'
namespace :hop do
  
  include TaskHelper
  
  def commons_member_sql
    "from contributions, sections, sittings  
     where contributions.section_id = sections.id and 
     sections.sitting_id = sittings.id and
     sittings.type != 'HouseOfLordsSitting' and 
     sittings.type != 'LordsWrittenStatementsSitting' and 
     sittings.type != 'LordsWrittenAnswersSitting' and
     sittings.type != 'GrandCommitteeReportSitting' and
     member_name is not null and 
     member_name != '' and
     member_name != 'Several Hon. Members' and
     member_name != 'HON. MEMBERS' and
     member_name != 'Several Hon Members' and
     member_name != 'An Hon. MEMBER'" 
  end

  def unmatched_contributions
    unmatched_contributions = Contribution.find_by_sql("select distinct member_name, constituency_name, count(member_name) as cnt 
                                              #{commons_member_sql} and
                                              commons_membership_id is null 
                                              group by member_name, constituency_name order by cnt desc limit 300;")
  end
  
  def unmatched_for_person(name)
    contributions = Contribution.find_by_sql(["SELECT contributions.* #{commons_member_sql} AND member_name = ? and 
                                       commons_membership_id is null", name])
                                       
    contributions.sort_by(&:date)
  end
  
  desc 'Show information on members in the database that can\'t be matched to people from the hop list'
  task :unmatched_people_details => :environment do 
    headings = ["Name", 
                "Constituency",
                "Unmatched count", 
                "First speech", 
                "House", 
                "Section title", 
                "Last speech", 
                "House",
                "Section title", 
                "Found person", 
                "Found person import id"]
    puts headings.join("\t")
    unmatched_contributions.each do |person_contribution|
      name = person_contribution.member_name
      count = person_contribution.cnt
      contributions = unmatched_for_person(name)
      first = contributions.first
      last = contributions.last
      name_hash = Person.name_hash(name)
      people = Person.find(:all, :conditions => ["lower(firstname) = ? and lower(lastname) = ?", name_hash[:firstname], name_hash[:lastname]])
      if people.size == 1
        found_person = people.first
      else
        found_person = nil
      end
      
      columns = [name, 
                 person_contribution.constituency_name, 
                 count,
                 first.date,
                 first.sitting_type, 
                 first.first_linkable_parent.title,
                 last.date, 
                 last.sitting_type, 
                 last.first_linkable_parent.title, 
                 found_person ? found_person.name : "", 
                 found_person ? found_person.import_id : ""]
      puts columns.join("\t")
    end
  end
  
  desc 'Display unmatched contributions for a name' 
  task :unmatched_for_person => :environment do 
    if ENV['name']
      name = ENV['name']
    else
      puts ''; puts 'usage: rake temp:unmatched_for_person name="name"'; puts ''
    end
    contributions = unmatched_for_person(name)
    first = contributions.first
    last = contributions.last
    constituency_contribs = contributions.select{|contribution| contribution.constituency_name }
    
    puts "First occurs #{first.date} #{first.sitting_type} #{first.first_linkable_parent.title} (contribution.id #{first.id})"
    puts "Last occurs #{last.date} #{last.sitting_type} #{last.first_linkable_parent.title} (contribution.id #{last.id})"
    
    constituency_contribs.each do |contribution|
      puts "Member for #{contribution.constituency_name} on #{contribution.date} #{contribution.sitting_type} #{contribution.first_linkable_parent.title}"
    end 
  end
  
  desc 'Display statistics on people matching'
  task :unmatched_people => :environment do 
  
    unmatched_contributions.each do |contribution|
      puts "#{contribution.member_name}\t#{contribution.constituency_name}\t#{contribution.cnt}"
    end
    
    commons_matchable_contributions = "select count(contributions.id) 
                                       #{commons_member_sql}"
    total_member_contributions = Contribution.count_by_sql(commons_matchable_contributions)
    matched_contributions = Contribution.count_by_sql(commons_matchable_contributions + " and commons_membership_id is not null")
    percent_success = (matched_contributions.to_f / total_member_contributions.to_f) * 100
    puts "Matched #{matched_contributions} out of #{total_member_contributions}: #{percent_success.round}%"
  end
  
  desc 'Match people to contributions'
  task :rematch_people => [:environment, "solr:disable_save"] do 
    process_contributions('commons_membership_id is not null and id > ?') do |contribution|
      contribution.commons_membership_id = nil
      contribution.save
    end
    process_sittings{ |sitting| sitting.match_people }
  end

  desc 'Create a members data file from the History of Parliament Access dump file' 
  task :create_members_file => :environment do 
    rows = []
    index = 0
    File.new(File.dirname(__FILE__) + "#{HOP_PATH}/tblElectedService.txt").each do |line|
     if index > 0
       attributes = parse_service_line(line)
       rows << attributes
     end
     index += 1
    end
    
    f = File.new("#{RAILS_ROOT}/reference_data/hop_data/commons_memberships.txt", 'w')
    rows.each do |attributes|
      f.write( [attributes[:import_id], attributes[:person_import_id], attributes[:constituency_import_id], attributes[:start_year], attributes[:start_date], attributes[:start_date_exact], attributes[:end_year], attributes[:end_date], attributes[:end_date_exact]].join("\t") + "\n")
    end
    f.close
     
  end
  
  def parse_service_line line
    d = line.split("\t")
    atts = { :import_id               => d[0].strip.to_i, 
             :person_import_id        => d[1].strip.to_i,
             :constituency_import_id  => d[2].strip.to_i,
             :start_year              => clean_year(d[4]),
             :start_date              => clean_date(d[5]),
             :start_date_exact        => d[6],
             :end_year                => clean_year(d[9]),
             :end_date                => clean_date(d[10]),
             :end_date_exact          => d[11] }
  end
  
  desc 'Merge dates from the Commons Library office holders into hop office holders (incomplete)'
  task :merge_office_holders => :environment do
    rows = []
    File.new("#{RAILS_ROOT}/reference_data/hop_data/office_holders.txt").each do |line|
       attributes = parse_office_holders_line(line) 
      
       if attributes[:office_import_id] == 1
         person = Person.find_by_import_id(attributes[:person_import_id])
         attributes[:person] = person
         attributes[:start_year], attributes[:end_year] = years_from_dates(attributes[:dates])
       end
       rows << attributes 
    end
    
    library_rows = []
    
    # These could probably also be matched lastname to person_import_id
    # but need to be verified.
    # {'Salisbury' => 9003, 
    #  'Gladstone' => 1687,
    #  'Derby' => 9049, 
    #  'Peel' => 6462,
    # }
    
    File.new("#{RAILS_ROOT}/reference_data/commons_library_data/library_office_holders.txt").each do |line|
       attributes = parse_library_office_holder_line(line) 
       if attributes[:office] == 'Prime Minister'
         attributes[:lastname] = Contribution.find_lastname(attributes[:holder])
         attributes[:firstname] = Contribution.find_firstname(attributes[:holder])
         library_rows << attributes 
         matches = rows.select do |row| 
           (row[:person] && row[:person].lastname == attributes[:lastname] && row[:start_year].to_i == attributes[:start_date].year)
         end
     
         if matches.empty?
           p "No matches #{attributes[:lastname]} #{attributes[:start_date].year}"
         elsif matches.size > 1
           p "Multiple matches #{attributes[:lastname]} #{attributes[:start_date].year}"
         else
           match = matches.first
           match[:start_date] = attributes[:start_date]
           match[:end_date] = attributes[:end_date]
         end
       end
    end
    
    f = File.new("#{RAILS_ROOT}/reference_data/hop_data/office_holders.txt", 'w')
    rows.each do |attributes|
      f.write( [attributes[:person_import_id], attributes[:office_import_id], attributes[:dates], attributes[:notes], attributes[:start_date], attributes[:end_date]].join("\t") + "\n")
    end
  
  end

  desc 'Create a people data file from the History of Parliament Access dump file' 
  task :create_people_file => :environment do 
    rows = []
    index = 0
    File.new(File.dirname(__FILE__) + "#{HOP_PATH}/tblIndividuals.txt").each do |line|
      if index > 0
        attributes = parse_individuals_line(line)
        rows << attributes
      end
      index += 1
    end
    
   f = File.new("#{RAILS_ROOT}/reference_data/hop_data/people.txt", 'w')
    last_id = 0
    rows.each_with_index do |attributes, index|
     
      raise attributes[:import_id] if attributes[:import_id] < last_id
      last_id = attributes[:import_id]
      unless attributes[:dummy_record]
        f.write( [attributes[:import_id], 
                  attributes[:full_firstnames], 
                  attributes[:firstname_used], 
                  attributes[:surname], 
                  attributes[:title], 
                  attributes[:year_of_birth], 
                  attributes[:date_of_birth], 
                  attributes[:date_of_birth_exact], 
                  attributes[:year_of_death],
                  attributes[:date_of_death], 
                  attributes[:date_of_death_exact]].join("\t") + "\n")
      end
   
    end
    f.close
  end
  
  def parse_individuals_line line
    d = line.split("\t")
    atts = { :import_id             => d[1].strip.to_i,
             :dummy_record          => d[3] == 'X',
             :full_firstnames       => clean_text(d[5]),
             :firstname_used        => clean_text(d[6]),
             :surname               => clean_text(d[7]),
             :title                 => clean_text(d[8]), 
             :year_of_birth         => clean_year(d[9]), 
             :date_of_birth         => clean_date(d[10]),
             :date_of_birth_exact   => clean_text(d[11]), 
             :year_of_death         => clean_year(d[12]),
             :date_of_death         => clean_date(d[13]),
             :date_of_death_exact   => clean_text(d[14]) }
  end
  
  desc 'Populate Lords memberships from file'
  task :populate_lords_memberships_from_file => :environment do 
    LordsMembership.delete_all
    hop_data_source = get_hop_data_source
    load_lords_memberships_from_file('lords_memberships.txt', 'hop_data', hop_data_source)
  end

  desc 'Populate Lords membership data from sql dump in reference data'
  task :populate_lords_memberships => :environment do 
    populate_table_from_sql_file('LordsMembership', 'hop_data')
  end
    
  desc 'Create peerages file'
  task :create_peerages_file => :environment do 
     rows = []
      index = 0
      File.new(File.dirname(__FILE__) + "#{HOP_PATH}/tblPeerages.txt").each do |line|
        if index > 0
          attributes = parse_hop_peerage_line(line)
          rows << attributes
        end
        index += 1
      end

     f = File.new("#{RAILS_ROOT}/reference_data/hop_data/lords_memberships.txt", 'w')
      last_id = 0
      rows.each_with_index do |attributes, index|
        f.write( [attributes[:import_id], 
                  attributes[:person_import_id], 
                  attributes[:number],
                  attributes[:degree],
                  attributes[:title],
                  attributes[:name],
                  attributes[:type],
                  attributes[:year]].join("\t") + "\n")
      end
      f.close
  end

  
  desc 'Print out a table of dates for which constituencies existed but we have no date on who represented them'
  task :missing_constituency_dates => :environment do 
    constituencies = Constituency.find(:all)
    puts "Constituency name\tStart date\tEnd date"
    constituencies.each do |constituency|
      constituency.missing_dates.each do |start_date, end_date|
        puts "#{constituency.name}\t#{start_date}\t#{end_date}"
      end
    end
  end
  
  desc 'Populate offices from reference data sql file'
  task :populate_offices => :environment do 
    populate_table_from_sql_file('Office', 'hop_data')
  end
  
  desc 'Populate offices from reference data text file'
  task :populate_offices_from_file => :environment do 
    Office.delete_all
    File.new("#{RAILS_ROOT}/reference_data/hop_data/offices.txt").each do |line|
      attributes = parse_offices_line(line) 
      Office.create!(attributes)
    end
  end
  
  def parse_offices_line(line)
    d = line.split("\t")
    atts = { :import_id => d[0].to_i,
             :name      => d[1], 
             :cabinet   => d[2].to_i == 1 ? true : false
           }
  end
  
  desc 'Create an offices data file from the History of Parliament Access dump file'
  task :create_offices_file => :environment do 
    rows = []
    File.new(File.dirname(__FILE__) + "#{HOP_PATH}/tblMinisterialOffices.txt").each do |line|
     attributes = parse_hop_offices_line(line)
     rows << attributes
    end

    f = File.new("#{RAILS_ROOT}/reference_data/hop_data/offices.txt", 'w')
    rows.each_with_index do |attributes, index|
      if index > 0
        f.write( [attributes[:import_id], attributes[:name], attributes[:cabinet], attributes[:notes]].join("\t") + "\n")
      end
    end
    f.close
  end
  
  def parse_hop_offices_line line
    d = line.split("\t")
    atts = { :import_id => d[0].to_i,
             :name      => clean_text(d[2]), 
             :cabinet   => d[3], 
             :notes     => clean_text(d[4].strip)
           }
  end
  
  desc 'Create office_holders file from History of Parliament Access dump'
  task :create_office_holders_file do 
    rows = []
    File.new(File.dirname(__FILE__) + "#{HOP_PATH}/tblMinisterialOfficesHeld.txt").each do |line|
      attributes = parse_hop_office_holders_line(line)
      rows << attributes
    end
    
    f = File.new("#{RAILS_ROOT}/reference_data/office_holders.txt", 'w')
    rows.each_with_index do |attributes, index|
      if index > 0
        f.write( [attributes[:individual_import_id], attributes[:office_import_id], attributes[:dates], attributes[:notes]].join("\t") + "\n")
      end
    end
    f.close
  end
  
  def parse_hop_office_holders_line(line)
    d = line.split("\t")
    atts = { :individual_import_id => d[0].to_i,
             :office_import_id     => d[1].to_i, 
             :dates                => clean_text(d[3])
           }
  end
  
  desc 'Populate offices from reference data sql file'
  task :populate_office_holders => :environment do 
    populate_table_from_sql_file('OfficeHolder', 'hop_data')
  end

  
  desc 'Populate office holders from reference data text file' 
  task :populate_office_holders_from_file => :environment do 
    hop_data_source = get_hop_data_source
    load_office_holders_from_file 'office_holders.txt', 'hop_data',  hop_data_source
  end
  
  def office_start_date_from_year(year, cabinet)
    start_date = Date.new(year.to_i, 1, 1)
    if cabinet
      elections = Election.find(:all, :conditions => ['YEAR(date) = ?', year])
      if elections.size == 1
        start_date = elections.first.date
      end
    end 
    start_date
  end
  
  def office_end_date_from_year(year, cabinet)
    end_date = Date.new(year.to_i, 12, 31)
    if cabinet
      elections = Election.find(:all, :conditions => ['YEAR(dissolution_date) = ?', year])
      if elections.size == 1
        end_date = elections.first.dissolution_date
      end
    end 
    end_date
  end

  
  desc 'Create elections file from History of Parliament Access database dump'
  task :create_elections_file do 
    rows = []
    index = 0
    File.new(File.dirname(__FILE__) + "#{HOP_PATH}/tblGeneralElections.txt").each do |line|
      if index > 0
        attributes = parse_hop_elections_line(line)
        rows << attributes
      end
      index += 1
    end

    f = File.new("#{RAILS_ROOT}/reference_data/hop_data/hop_data/elections.txt", 'w')
    rows.each do |attributes, index|   
      f.write( [attributes[:import_id], attributes[:date], attributes[:dissolution_date]].join("\t") + "\n")
    end
    f.close
  end
  
  def parse_hop_elections_line(line)
    d = line.split("\t")
    atts = {:import_id        => d[0].to_i,
            :date             => clean_date(d[1]),
            :dissolution_date => clean_date(d[3])
           }
  end
  
  desc 'Populate elections from reference data text file'
  task :populate_elections => :environment do 
    File.new("#{RAILS_ROOT}/reference_data/hop_data/elections.txt").each do |line|
      attributes = parse_elections_line(line) 
      Election.create!(attributes)
    end
  end
  
  def parse_elections_line(line)
    d = line.split("\t")
    atts = { :import_id        => d[0].to_i,
             :date             => Date.parse(d[1]),
             :dissolution_date => d[2].blank? ? nil : Date.parse(d[2].strip)  }
  end
  
  desc 'Populate people from reference data sql file' 
  task :populate_people => :environment do 
    populate_table_from_sql_file('Person', 'hop_data')
  end
  
  desc 'Populate commons memberships from reference data sql file' 
  task :populate_commons_memberships => :environment do 
    populate_table_from_sql_file('CommonsMembership', 'hop_data')
  end
  
  def get_hop_data_source
    hop_data_source = DataSource.find_by_name("History of Parliament Trust")
    raise "Couldn't find 'History of Parliament Trust' data source" unless hop_data_source
    hop_data_source
  end
  
  desc 'Populate people from reference data text file'
  task :populate_people_from_file => :environment do 
    Person.delete_all
    hop_data_source = get_hop_data_source
    load_people_from_file('people.txt', 'hop_data', hop_data_source)
  end
    
  desc 'Populate commons memberships from reference data text file' 
  task :populate_commons_memberships_from_file => :environment do 
    CommonsMembership.delete_all
    hop_data_source = get_hop_data_source
    load_commons_memberships_from_file('commons_memberships.txt', 'hop_data', hop_data_source)
  end

  desc 'Create a constituencies data file from the History of Parliament Access dump file'
  task :create_constituencies_file => :environment do 
    rows = []
    File.new(File.dirname(__FILE__) + "#{HOP_PATH}/tblConstituencies.txt").each do |line|
      attributes = parse_hop_constituencies_line(line)
      rows << attributes
    end
    
    f = File.new("#{RAILS_ROOT}/reference_data/hop_data/constituencies.txt", 'w')
    rows.each_with_index do |attributes, index|
      if index > 0
        f.write( [attributes[:import_id], attributes[:name], attributes[:start_year], attributes[:end_year]].join("\t") + "\n")
      end
    end
    f.close
  end
  
  def parse_hop_constituencies_line line
    d = line.split("\t")
    atts = { :import_id  => d[0].strip.to_i,
             :name       => clean_text(d[1]),
             :start_year => clean_year(d[11]),
             :end_year   => clean_year(d[12])
           }
  end

  
  desc 'Populate constituencies data from sql dump in reference data'
  task :populate_constituencies => :environment do 
    populate_table_from_sql_file('Constituency', 'hop_data')
  end
  
  desc 'Populate constituencies data from the reference data file'
  task :populate_constituencies_from_file => :environment do 
    puts "Populating constituencies from reference data"
    hop_data_source = get_hop_data_source
    load_constituencies_from_file('constituencies.txt', 'hop_data', hop_data_source)
  end
  
  desc 'Create alternative names file from History of Parliament Access dump file' 
  task :create_alternative_names_file => :environment do 
    rows = []
    index = 0
    File.new(File.dirname(__FILE__) + "#{HOP_PATH}/tblAlternativeSurnames.txt").each do |line|
     if index > 0
       attributes = parse_hop_alternative_names_line(line)
       rows << attributes
     end
     index += 1
    end
    
    f = File.new("#{RAILS_ROOT}/reference_data/hop_data/alternative_names.txt", 'w')
    rows.each do |attributes| 
      f.write( [attributes[:import_id], 
                attributes[:person_import_id],
                attributes[:alternative_lastname], 
                attributes[:alternative_firstname], 
                attributes[:alternative_full_firstnames], 
                attributes[:alternative_title], 
                attributes[:alternative_name_type], 
                attributes[:start_year],
                attributes[:end_year],              
                attributes[:notes]].join("\t") + "\n")
    end
    f.close
    
  end
  
  def parse_hop_alternative_names_line(line)
    d = line.split("\t")
    atts = { :import_id                   => d[0].to_i, 
             :person_import_id            => d[1].to_i,
             :alternative_lastname        => clean_text(d[2]), 
             :alternative_firstname       => clean_text(d[3]),
             :alternative_full_firstnames => clean_text(d[4]), 
             :alternative_title           => clean_text(d[5]),
             :alternative_name_type       => clean_text(d[6]),
             :start_year                  => clean_year(d[7]), 
             :end_year                    => clean_year(d[8]), 
             :notes                       => clean_text(d[9]) }
  end
  
  
  desc 'Populate alternative names from reference data sql file'
  task :populate_alternative_names => :environment do 
    populate_table_from_sql_file('AlternativeName', 'hop_data')
  end
  
  desc 'Populate alternative names from reference data text file'
  task :populate_alternative_names_from_file => :environment do 
    hop_data_source = get_hop_data_source
    load_alternative_names_from_file('alternative_names.txt', 'hop_data', hop_data_source)
  end

end
