module TaskHelper

  def populate_table_from_sql_file(name, directory, filename=nil)
    start_time = Time.now
    table_name = name.tableize
    filename = filename || table_name
    model_class = name.constantize
    puts "Populating #{table_name} from #{directory} reference data"
    db_atts = db_attributes(model_class)
    system "mysql #{mysql_flags(db_atts)} #{db_atts[:database]} < #{RAILS_ROOT}/reference_data/#{directory}/#{filename}.sql"
    TIMINGS << "populating #{table_name} took: #{(Time.now - start_time).to_s}"
  end
  
  def dump_table_to_sql_file(name, directory, filename=nil)
    table_name = name.tableize
    filename = filename || table_name
    model_class = name.constantize
    puts "Dumping #{table_name} to #{directory} reference data"
    db_atts = db_attributes(model_class)
    system "mysqldump #{mysql_flags(db_atts)} #{db_atts[:database]} #{table_name} > #{RAILS_ROOT}/reference_data/#{directory}/#{filename}.sql"
  end
  
  def db_attributes(model_class)
    {:username => model_class.configurations[RAILS_ENV]['username'],
     :password => model_class.configurations[RAILS_ENV]['password'],
     :database => model_class.configurations[RAILS_ENV]['database'] }
  end
  
  def mysql_flags(db_atts)
    mysql_flags = "-u #{db_atts[:username]} "
    mysql_flags += "-p#{db_atts[:password]} " unless db_atts[:password].blank?
    mysql_flags
  end
  
  def process_model model, condition='id > ?', limit=200
    last_id = 0
    instance_names = model.name.pluralize.downcase
    begin
      puts "Processing #{instance_names}..."
      instances = model.find(:all, :conditions => [condition, last_id], :limit => limit)
      last_id = instances.last.id if !instances.empty?
      instances.each do |instance|
        begin
          yield instance
        rescue Exception => e
          puts e.to_s
          puts e.backtrace
          puts 'continuing ...'
        end
      end
      puts "Processed #{instances.size} #{instance_names} of #{model.count}, last id was #{last_id}"
    end while instances.size > 0
  end
  
  def process_contributions condition='member_suffix is not null and constituency_id is null and id > ?', &proc
    process_model(Contribution, condition, &proc)
  end
  
  def process_sections condition='id > ?', &proc
    process_model(Section, condition, &proc)
  end

  def process_people condition='id > ?', &proc
    process_model(Person, condition, &proc)
  end
 
  def process_offices condition='id > ?', &proc
    process_model(Office, condition, &proc)
  end
  
  def process_acts condition='id > ?', &proc
    process_model(Act, condition, &proc)
  end
  
  def process_bills condition='id > ?', &proc
    process_model(Bill, condition, &proc)
  end
  
  def process_sittings condition='id > ?', &proc
    process_model(Sitting, condition, limit=20, &proc)
  end

  def process_divisions condition='id > ?', &proc
    process_model(Division, condition, &proc)
  end
  
  def parse_library_office_holder_line line
    d = line.split("\t")
    atts = { :start_date  => Date.parse(d[0]),
             :holder      => d[2].strip,
             :office      => d[3].strip,
             :updated_on  => d[4]
           }
    atts[:end_date] = Date.parse(d[1]) if !d[1].blank?
    atts
  end
  
  def match_people(offset, limit)
    process_sittings("id > #{offset} and id <= #{limit} and id > ?") do |sitting|
      sitting.match_people
      sitting.save!
      print '.'
      $stdout.flush 
    end
  end
  
  def calculate_process_thread_limit(max_id, parse_processes, index)
    limit = (max_id / parse_processes ) * (index+1)
    limit = max_id if index+1 == parse_processes
    limit
  end
  
  def calculate_process_thread_offset(max_id, parse_processes, index)
    ((max_id / parse_processes ) * index)
  end
  
  def parse_people_line line
    d = line.split("\t")
    atts = { :import_id               => d[0].to_i,
             :full_firstnames         => d[1], 
             :firstname               => d[2], 
             :lastname                => d[3],
             :honorific               => d[4].strip, 
             :year_of_birth           => d[5].blank? ? nil : d[5].to_i,
             :date_of_birth           => d[6].blank? ? nil : Date.parse(d[6]),
             :estimated_date_of_birth => d[7] == "TRUE" ? false : true, 
             :year_of_death           => d[8].blank? ? nil : d[8].to_i,
             :date_of_death           => d[9].blank? ? nil : Date.parse(d[9]),  
             :estimated_date_of_death => d[10].strip == "TRUE" ? false : true
           }
  end
  
  def create_person_from_line(line, data_source)
    line = Iconv.new('UTF-8//TRANSLIT', 'ISO-8859-1').iconv(line)
    attributes = parse_people_line(line) 
    attributes = estimate_date(attributes, :date_of_birth, :year_of_birth, :estimated_date_of_birth, start=true)    
    attributes = estimate_date(attributes, :date_of_death, :year_of_death, :estimated_date_of_death, start=false)
    attributes[:data_source_id] = data_source.id
    Person.create!(attributes)
  end
  
  def load_people_from_file filename, directory, data_source
    File.new("#{RAILS_ROOT}/reference_data/#{directory}/#{filename}").each do |line|
      create_person_from_line(line, data_source)
    end
  end
  
  def load_alternative_titles_from_file(filename, directory, data_source) 
    File.new("#{RAILS_ROOT}/reference_data/#{directory}/#{filename}").each do |line|
      create_alternative_title_from_line(line, data_source)
    end
  end  
  
  def get_peerage_attributes(line, data_source)
    person = nil
    attributes = parse_peerage_line(line)
    if ! attributes[:start_year]
      puts "no start year for lords membership #{attributes[:name]} (#{attributes[:import_id]})"
      attributes = nil
    else
      person_import_id = attributes.delete(:person_import_id)
      person = Person.find_by_import_id(person_import_id)
      if person
        attributes = estimate_date(attributes, :start_date, :start_year, :estimated_start_date, start=true)
        attributes = estimate_date(attributes, :end_date, :end_year, :estimated_end_date, start=false)    
        unless attributes[:end_date]
          attributes[:end_date] = person.date_of_death 
          attributes[:estimated_end_date] = person.estimated_date_of_death
        end
        attributes.update(:person_id => person.id, 
                          :data_source_id => data_source.id)
      end
    end
    [person, attributes]
  end
  
  def create_alternative_title_from_line(line, data_source)
    person, attributes = get_peerage_attributes(line, data_source)
    return unless attributes
    attributes[:title_type] = attributes.delete(:membership_type)
    if person
      if existing_alternative_title = AlternativeTitle.find(:first, 
                                                            :conditions => ['person_id = ? and degree = ? and title = ? and number = ? and year(start_date) = ? and title_type = ?',
                                                            person.id, 
                                                            attributes[:degree], 
                                                            attributes[:title], 
                                                            attributes[:number], 
                                                            attributes[:start_date].year, 
                                                            attributes[:title_type]])
        existing_alternative_title.update_attributes(attributes)
      else
        alternative_title = AlternativeTitle.create!(attributes)    
      end
    end
  end
  
  def load_alternative_names_from_file(filename, directory, data_source)
    File.new("#{RAILS_ROOT}/reference_data/#{directory}/#{filename}").each do |line|
      create_alternative_name_from_line(line, data_source)
    end
  end
  
  def parse_alternative_names_line(line)
    d = line.split("\t")
    atts = { :import_id        => d[0].to_i, 
             :person_import_id => d[1].to_i,
             :lastname         => d[2], 
             :firstname        => d[3],
             :full_firstnames  => d[4], 
             :honorific        => d[5],
             :name_type        => d[6],
             :start_year       => d[7].to_i, 
             :end_year         => d[8].to_i, 
             :notes            => d[9] }
  end
  
  def create_alternative_name_from_line(line, data_source)
    line = Iconv.new('UTF-8//TRANSLIT', 'ISO-8859-1').iconv(line)
    attributes = parse_alternative_names_line(line)
    start_year = attributes.delete(:start_year)
    end_year = attributes.delete(:end_year)
    import_id = attributes.delete(:person_import_id)
    person = Person.find_by_import_id(import_id)
    start_date = nil
    end_date = nil
    if start_year == 0
     if person.date_of_birth
       start_date = person.date_of_birth
     else
       start_date = Date.new(FIRST_DATE.year , 1, 1)
     end
    else
     start_date = Date.new(start_year , 1, 1)
    end
    if end_year == 0
     if person.date_of_death
       end_date = person.date_of_death
     else
       end_date = Date.new(LAST_DATE.year, 12, 31)
     end
    else 
     end_date = Date.new(end_year, 12, 31)
    end
    attributes[:person_id] = person.id
    attributes[:start_date] = start_date
    attributes[:end_date] = end_date
    attributes[:estimated_start_date] = true
    attributes[:estimated_end_date] = true
    attributes.delete(:notes)
    AlternativeName.create(attributes)
    print '.'
    $stdout.flush

  end
  
  def parse_peerage_line(line)
    d = line.split("\t")
    atts = { :import_id             => d[0].to_i,
             :person_import_id      => d[1].to_i,
             :number                => d[2],
             :degree                => d[3],
             :title                 => d[4],
             :name                  => d[5],
             :membership_type       => d[6],
             :start_year            => d[7].blank? ? nil : d[7].to_i, 
             :start_date            => d[8].blank? ? nil : Date.parse(d[8]),
             :end_year              => d[9].blank? ? nil : d[9].to_i, 
             :end_date              => d[10].blank? ? nil : Date.parse(d[10])}
  end
  
  def parse_hop_peerage_line(line)
    d = line.split("\t")
    atts = { :import_id             => d[0].strip.to_i,
             :person_import_id      =>  d[1].strip.to_i,
             :number                => clean_text(d[2]),
             :degree                => clean_text(d[3]),
             :title                 => clean_text(d[4]),
             :name                  => clean_text(d[5]),
             :type                  => clean_text(d[6]),
             :year                  => clean_year(d[7])
             }
  end
  
  def create_lords_membership_from_line(line, data_source)
    person, attributes = get_peerage_attributes(line, data_source)
    return unless attributes
    if person
      if existing_membership = LordsMembership.find(:first, 
                                                    :conditions => ['person_id = ? and degree = ? and title = ? and number = ? and year(start_date) = ?',
                                                    person.id, 
                                                    attributes[:degree], 
                                                    attributes[:title], 
                                                    attributes[:number], 
                                                    attributes[:start_date].year])
        existing_membership.update_attributes(attributes)
      else
        membership = LordsMembership.create!(attributes)    
      end
    end

  end
  
  def parse_members_line line
    d = line.split("\t")
    atts = { :import_id               => d[0].to_i,
             :person_import_id        => d[1].to_i, 
             :constituency_import_id  => d[2].to_i,
             :start_year              => clean_year(d[3]),
             :start_date              => d[4].blank? ? nil : Date.parse(d[4]),
             :end_year                => clean_year(d[6]),
             :end_date                => d[7].blank? ? nil : Date.parse(d[7])
           }
  end
  
  def create_commons_membership_from_line(line, data_source)
    attributes = parse_members_line(line)
    return if attributes[:start_date] and attributes[:start_date] > LAST_DATE
    person_import_id = attributes.delete(:person_import_id)
    constituency_import_id = attributes.delete(:constituency_import_id)
    person = Person.find_by_import_id(person_import_id)
    constituency = Constituency.find_by_import_id(constituency_import_id)
    if person and constituency
      attributes = estimate_date(attributes, :start_date, :start_year, :estimated_start_date, start=true)    
      attributes = estimate_date(attributes, :end_date, :end_year, :estimated_end_date, start=false)
      attributes.update(:constituency_id => constituency.id, 
                        :person_id       => person.id, 
                        :data_source_id  => data_source.id)
      if existing_membership = CommonsMembership.find(:first, 
                                             :conditions => ["person_id = ? and constituency_id = ? and (start_date = ? or end_date = ?)", 
                                             person.id, 
                                             constituency.id, 
                                             attributes[:start_date], 
                                             attributes[:end_date]])
        existing_membership.update_attributes(attributes)
      else 
        membership = CommonsMembership.create(attributes)
      end
    end
  end
  
  def estimate_date attributes, date_attribute, year_attribute, estimated_attribute, start
    year = attributes.delete(year_attribute)
    if attributes[date_attribute].nil? and year
      date = start ? Date.new(year, 1, 1) : Date.new(year, 12, 31)
      attributes[date_attribute] = date
      attributes[estimated_attribute] = true
    else
      if attributes[estimated_attribute] == nil
        attributes[estimated_attribute] = false
      end
    end
    attributes
  end
  
  def load_commons_memberships_from_file filename, directory, data_source
    File.new("#{RAILS_ROOT}/reference_data/#{directory}/#{filename}").each do |line|
      create_commons_membership_from_line(line, data_source)
    end
  end  
  
  def load_lords_memberships_from_file filename, directory, data_source
    File.new("#{RAILS_ROOT}/reference_data/#{directory}/#{filename}").each do |line|
      create_lords_membership_from_line(line, data_source)
    end
  end
  
  def office_start_date_from_year(year, cabinet)
    start_date = Date.new(year, 1, 1)
    if cabinet
      elections = Election.find_all_by_year(year)
      if elections.size == 1
        start_date = elections.first.date
      end
    end 
    start_date
  end
  
  def office_end_date_from_year(year, cabinet)
    end_date = Date.new(year.to_i, 12, 31)
    if cabinet
      elections = Election.find_all_by_dissolution_year(year)
      if elections.size == 1
        end_date = elections.first.dissolution_date
      end
    end 
    end_date
  end
  
  def parse_office_holders_line(line)
    d = line.split("\t")
    atts = { :person_import_id     => d[0].to_i,
             :office_import_id     => d[1].to_i, 
             :dates                => d[2].strip
           }
        
    atts[:start_date] = Date.parse(d[4]) unless d[4].blank?
    atts[:end_date] = Date.parse(d[5]) unless d[5].blank?
    atts
  end
  
  def years_from_dates(dates)
    date_pairs = []
    date_ranges = dates.split(/\.|;|,/)
    date_ranges.each do |date_range|
      date_parts = date_range.split(/-/)
      start_year = date_parts.first.blank? ? nil : date_parts.first.to_i
      end_year = end_year_from_date_parts(date_range, date_parts, start_year)
      date_pairs << [start_year, end_year]
    end
    if dates.blank?
      date_pairs << [nil, nil]
    end
    date_pairs
  end
  
  def end_year_from_date_parts(date_range, date_parts, start_year)
    end_year = nil
    if date_parts.size > 1
      end_year = date_parts.last
      if end_year.size < 4
        end_year = (date_parts.first[0, 4-end_year.size] + end_year)
      end
      if multi_year_match = /(\d\d\d)\d\/(\d)/.match(end_year)
        end_year = multi_year_match[1] + multi_year_match[2]
      end
    else
      end_year = start_year if !/-/.match(date_range)
    end
    end_year = end_year.to_i if end_year
    end_year
  end
  
  def create_office_holder_from_line line, data_source
    attributes = parse_office_holders_line(line) 
    date_pairs = years_from_dates(attributes.delete(:dates))
    office = Office.find_by_import_id(attributes.delete(:office_import_id))
    person = Person.find_by_import_id(attributes.delete(:person_import_id))
    if office and person
      attributes.update({:person_id => person.id, 
                         :office_id => office.id, 
                         :confirmed => true, 
                         :data_source_id => data_source.id})
      original_start_date = attributes[:start_date]
      original_end_date = attributes[:end_date]
      date_pairs.each do |start_year, end_year|
        attributes[:start_date] = original_start_date
        attributes[:end_date] = original_end_date
        if start_year and ! attributes[:start_date]
          attributes[:start_date] = office_start_date_from_year(start_year, office.cabinet)
          attributes[:estimated_start_date] = true
        else
          attributes[:estimated_start_date] = false
        end
        if end_year and ! attributes[:end_date]
          attributes[:end_date] = office_end_date_from_year(end_year, office.cabinet)
          attributes[:estimated_end_date] = true
        else
          attributes[:estimated_end_date] = false
        end
        if existing_holder = OfficeHolder.find(:first, 
                             :conditions => ["person_id = ? and office_id = ? and (YEAR(start_date) = ? or YEAR(end_date) = ?)", 
                             person.id, 
                             office.id, 
                             (attributes[:start_date] ? attributes[:start_date].year : nil), 
                             (attributes[:end_date] ? attributes[:end_date].year : nil)])
          existing_holder.update_attributes(attributes)
        else
          OfficeHolder.create!(attributes)
        end
      end
    end
  end
  
  def load_office_holders_from_file filename, directory, data_source
    File.new("#{RAILS_ROOT}/reference_data/#{directory}/#{filename}").each do |line|
      create_office_holder_from_line(line, data_source)
    end
  end
  
  def parse_constituencies_line line
    d = line.split("\t")
    atts = { :import_id  => d[0].to_i,
             :name       => d[1],
             :start_year => clean_year(d[2]),
             :end_year   => clean_year(d[3])
           }
  end
  
  def create_constituency_from_line line, data_source
    square_bracket_pattern = /\[(.*?)\]/
    line = Iconv.new('UTF-8//TRANSLIT', 'ISO-8859-1').iconv(line)
    attributes = parse_constituencies_line(line)
    return nil if attributes[:start_year] and attributes[:start_year] > LAST_DATE.year
    attributes[:data_source_id] = data_source.id
    if (square_bracket = square_bracket_pattern.match attributes[:name])
      bracket_text =  square_bracket[1]
      return nil if bracket_text == 'Constituency unknown'
      attributes[:name].gsub!(square_bracket_pattern, '')
      attributes[:name].strip!
      words = bracket_text.split(/, /)
      words.each do |word|
        if word.downcase == word
          attributes[:area_type] = word
        else
          attributes[:region] = word
        end
      end
    end
    existing_constituency = Constituency.find_by_import_id(attributes[:import_id])
    if existing_constituency
      existing_constituency.update_attributes(attributes)
    else
      Constituency.create!(attributes)
    end
  end
  
  def load_constituencies_from_file filename, directory, data_source
    File.new("#{RAILS_ROOT}/reference_data/#{directory}/#{filename}").each do |line|
      create_constituency_from_line(line, data_source)
    end
  end
  
  def parse_parliament_session_line line
    d = line.split("\t")
    session_years = d[7].strip
    session_year_list = session_years.split('-')
    atts = { :source_file_name => d[6],
             :session_start_year => session_year_list.first.to_i, 
             :session_end_year => session_year_list.last.to_i
           }
    atts
  end
  
  def create_parliament_sessions_from_attributes attribute_list
    attribute_list.each do |attributes|
      parliament_session = ParliamentSession.find_or_create_by_start_year_and_end_year(attributes[:session_start_year], attributes[:session_end_year])
      data_file = SourceFile.find_by_name(attributes[:source_file_name])
      if data_file and data_file.volume
        data_file.volume.update_attribute(:parliament_session_id, parliament_session.id)
      end
    end
  end
  
  def load_parliament_sessions_from_file filename, directory, data_source
    attribute_list = []
    File.new("#{RAILS_ROOT}/reference_data/#{directory}/#{filename}").each_with_index do |line, index|
      if index > 0
        attribute_list << parse_parliament_session_line(line)
      end
    end
    create_parliament_sessions_from_attributes(attribute_list)
  end
  
  def seats_for_year seats_list, year
    seats_list.each_with_index do |seats_info, index|
      seat_year, seats = seats_info
      if seat_year > year
        return seats_list[index-1][1]
      end
    end
    return seats_list.last[1]
  end
  
  def clean_year year
    year = clean_text(year)
    if (four_digit_year = /\d\d\d\d/.match(year))
      return four_digit_year[0].to_i
    end
    nil
  end
  
  def clean_text text
    if text
      text = text.gsub('"', '')
      text.strip
    end    
  end
  
  def clean_date date_string
    if !date_string.blank?
      date_string = date_string.split[0] 
      date_string = date_string.gsub(/(\d+)\/(\d+)\/(\d+)/, '\2/\1/\3') 
      begin
        Date.parse(date_string)
      rescue
        nil
      end
    end
  end
  
end