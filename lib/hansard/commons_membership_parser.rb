class Hansard::CommonsMembershipParser < Hansard::MembershipParser
  
  NEW_CONSTITUENCIES_FILE = "#{RAILS_ROOT}/reference_data/commons_library_data/constituencies.txt"
  CONSTITUENCY_MATCH_FILE = "#{RAILS_ROOT}/reference_data/commons_library_data/constituency_matches.txt"
  COMMONS_MEMBERSHIPS_FILE = "#{RAILS_ROOT}/reference_data/commons_library_data/commons_memberships.txt"
  LAST_LOAD_YEAR = 1900
  FIRST_YEAR_OF_EXISTING_DATA = 1832
  
  attr_accessor :current_membership, :current_constituency, :html, :constituency_interval
  attr_accessor :memberships, :constituency_classes, :constituency_end_classes
  attr_accessor :constituency_end, :in_constituency_start, :in_constituency_end
  attr_accessor :in_membership_set, :parsed, :constituencies
  attr_accessor :current_constituency_start_date, :current_constituency_end_date
  
  @@new_people = Hash.new{ |hash, key| hash[key] = [] }

  def initialize file
    self.memberships = []
    self.constituencies = {}
    @file = file
  end

  def parse(text=nil)
    self.parsed = true
    text = text || open(@file).read
    text = text.gsub(/<!-*->/, '')
    self.html = Hpricot(text)
    self.html.search('span').remove
    self.html.search("[@colspan='4']").remove
    get_constituency_classes
    self.current_membership = new_membership
    self.html.search('tr').each{ |row| handle_row(row) }
    filter_memberships_for_dates
    self.memberships
  end
  
  def new_people
    @@new_people
  end
  
  def add_memberships
    parse unless self.parsed
    self.memberships.each do |membership| 
      add_membership(membership) if membership[:start_date] < Date.new(LAST_LOAD_YEAR, 1, 1) 
    end
  end
  
  def member_info membership
    "#{membership[:name]} #{membership[:firstnames]} #{membership[:lastname]} ( #{membership[:date_of_birth]}-#{membership[:date_of_death]}) #{membership[:start_date]} #{membership[:end_date]}"
  end
  
  def find_constituency(membership)
    constituency_name = membership[:constituency]
    start_date = membership[:start_date]
    end_date = membership[:end_date]
    return nil unless start_date and end_date
    self.constituency_matches.each do |constituency_info, id|
      cons_name, cons_start_year, cons_end_year = constituency_info 
      if constituency_name == cons_name or normalize_space(constituency_name) == cons_name
        if (!cons_end_year or start_date.year <= cons_end_year) and end_date.year >= cons_start_year 
          return id
        end
      end
    end
    return nil
  end
  
  def add_membership(membership)
    import_id = find_constituency(membership)
    if import_id.blank?
      puts "No match for Constituency #{membership[:constituency]} #{membership[:start_date]} #{membership[:end_date]} #{membership[:end_year]}"
      return
    end
    constituency = Constituency.find_by_import_id(import_id)
    membership_exists = match_membership(membership, constituency)
    if ! membership_exists
      person = match_person(membership)
      if person
         # puts "#{person.full_firstnames} #{person.lastname} (#{person.date_of_birth}-#{person.date_of_death}) #{member_info(membership)}"
        save_membership(membership, constituency, person)
      elsif multiple_people?(membership)
        # puts "AMBIGUOUS #{membership[:name]} #{membership[:firstnames]} #{membership[:lastname]} (#{membership[:date_of_birth]}-#{membership[:date_of_death]}) #{membership[:start_date]} #{membership[:end_date]}"
      else  
        # puts "NO MATCH NEW NAME #{membership[:name]} #{membership[:firstnames]} #{membership[:lastname]} (#{membership[:date_of_birth]}-#{membership[:date_of_death]}) #{membership[:start_date]} #{membership[:end_date]}"
        add_to_new_people(membership, constituency)
      end
      
    end
  end
  
  def add_to_new_people(membership, constituency)
    membership[:constituency_model] = constituency
    person_attributes = [membership[:firstnames],
                         membership[:firstname], 
                         membership[:lastname], 
                         membership[:year_of_birth], 
                         membership[:date_of_birth],
                         membership[:year_of_death],
                         membership[:date_of_death]]
    @@new_people[person_attributes] << membership
  end
  
  def multiple_people?(membership)
     people = Person.find_all_by_name_birth_year_and_date_of_death(membership)
     people += Person.find_all_by_name_and_date_of_death_exact(membership)
     people += Person.find_all_by_name_birth_and_death_years_estimated(membership)
     people += Person.find_all_by_name_and_death_year_estimated(membership)
     return true if people.size > 1
     return false
  end
  
  def save_person(person)
    next_id = last_people_id + 1
    open(PEOPLE_FILE, 'a') do |people_file| 
      attributes = [next_id, 
                 person[:firstnames], 
                 person[:firstname],
                 person[:lastname], 
                 person[:honorific],
                 person[:year_of_birth],
                 person[:date_of_birth], 
                 person[:date_of_birth] ? 'TRUE' : 'FALSE',
                 person[:year_of_death],
                 person[:date_of_death], 
                 person[:date_of_death] ? 'TRUE' : 'FALSE'
               ]
      people_file.write "#{attributes.join("\t")}\n"  
    end  
    next_id
  end
  
  def save_membership(membership, constituency, person)
    next_id = last_commons_membership_id + 1
    open(COMMONS_MEMBERSHIPS_FILE, 'a') do |membership_file|   
      if membership[:start_date] and membership[:end_date]
        attributes = [next_id, 
                      person.import_id, 
                      constituency.import_id, 
                      membership[:start_date].year,
                      membership[:start_date],
                      '',
                      membership[:end_date].year,
                      membership[:end_date]]

        
         membership_file.write "#{attributes.join("\t")}\n"
      else
        puts "Not saving, incomplete dates #{member_info(membership)}"
      end
    end  
  end
  
  def last_commons_membership_id
    last_id(COMMONS_MEMBERSHIPS_FILE)
  end
  
  def match_membership(membership, constituency)
    return false if membership[:end_date].year <= FIRST_YEAR_OF_EXISTING_DATA
    constituency.commons_memberships.each do |commons_membership|
      if commons_membership.match_by_year(membership)
        return commons_membership 
      end
      if commons_membership.match_by_overlap_and_name(membership)
        return commons_membership 
      end
    end
    return false
  end
  
  def get_constituency_classes
    self.constituency_classes = []
    self.constituency_end_classes = []
    style_text = self.html.search('style').inner_html
    cell_style_pattern = /\.xl\d+\s*\{.*?\}/im
    styles = style_text.scan(cell_style_pattern)
    styles.each do |style|
      cell_class = /\.xl\d+/.match(style)
      if highlight = /background:yellow;/.match(style)
        self.constituency_classes << cell_class[0]
      elsif /border(-left)?:1.0pt solid windowtext;/.match(style) and /color:blue;/.match(style)
        self.constituency_end_classes << cell_class[0]
      end
    end
  end
  
  def handle_row(row)
    if start_text = constituency_text(row)
      handle_constituency_start_text(start_text)
    elsif end_text = constituency_end_text(row)
     handle_constituency_end_text(end_text)
    else
      handle_constituency_start if self.in_constituency_start      
      handle_constituency_end if self.in_constituency_end
      handle_membership_row(row)
    end
  end
  
  def handle_constituency_start_text(start_text)
    if self.in_constituency_start
      self.current_constituency += " #{start_text}"
    else
      if self.current_constituency
        self.constituency_end = ''
        self.handle_constituency_end
      end
      self.current_constituency = start_text
    end
    self.in_constituency_start = true
  end
  
  def handle_constituency_start
    self.in_constituency_start = false
  end
  
  def handle_constituency_end_text(end_text)
    if self.in_constituency_end
      self.constituency_end += " #{end_text}"
    else
      self.constituency_end = end_text
    end
    self.in_constituency_end = true
  end
  
  def revival_pattern
    /(REVIVED|RE-?UNITED|REVERTED|ALTERED BACK)/
  end
  
  def handle_constituency_end
    end_date = constituency_end_date(self.constituency_end)
    if /RES?PRESENTATION/.match(self.constituency_end)
    elsif revival_pattern.match(self.constituency_end) 
      set_constituency_end_date(end_date)
      add_constituency
      self.current_constituency_start_date = constituency_revival(self.constituency_end)
      self.current_constituency_end_date = nil
    else
      set_constituency_end_date(end_date)
      add_constituency
      self.current_constituency_start_date = nil
      self.current_constituency_end_date = nil
      self.current_constituency = nil
    end
    self.in_constituency_end = false
  end
  
  def normalize_space(constituency)
    constituency.gsub('(', ' (').squeeze(' ')
  end
  
  def add_constituency
    constituency = [self.current_constituency, 
                    self.current_constituency_start_date, 
                    self.current_constituency_end_date]
    self.constituencies[constituency] = []
  end
  
  def set_constituency_end_date(date)
    self.current_constituency_end_date = date
    return unless date
    return unless self.memberships.last
    return unless self.memberships.last[:constituency] == self.current_constituency
    self.memberships.last[:end_date] = date
    if set_date = self.memberships.last[:set]
      index = self.memberships.size - 1
      while is_set_member?(self.memberships.last, self.memberships[index]) and index >= 0
        if self.memberships[index][:end_date].blank?
          self.memberships[index][:end_date] = date
        end
        index -= 1
      end
    end
  end
  
  def constituency_end_date(end_text)
    if year_match = /\d\d\d\d/.match(end_text)
      year = year_match[0].to_i
      return date_for_year(year)
    end
    return nil
  end
  
  def constituency_revival(end_text)
    if revival_year_match = /\d\d\d\d.*(\d\d\d\d)/.match(end_text)
      year = revival_year_match[1].to_i
      return date_for_year(year, end_year=false)
    end
    return nil
  end
  
  def date_for_year year, end_year=true
    elections = Election.find_all_by_year(year)
    return elections.last.date if !elections.empty? 
    if end_year
      return Date.new(year, 12, 31) 
    else
      return Date.new(year, 1, 1)
    end
  end
  
  def filter_memberships_for_dates
    self.memberships = self.memberships.select do |membership|
      if membership[:start_date].blank? 
        false
      else
        membership[:start_date] < LAST_DATE and (membership[:end_date].blank? or membership[:end_date] > FIRST_DATE) 
      end
    end
    self.memberships
  end
  
  def handle_membership_row(row)
    return unless self.current_constituency
    if empty_row?(row) 
      handle_empty_row
      return
    end
    if has_dates?(row_data(row)) and has_dates?(self.current_membership)
      add_membership_to_memberships
      add_membership_data_from_row(row)
      set_start_date_from_last
    else 
      add_membership_data_from_row(row)
    end
  end
  
  def set_start_date_from_last
    self.current_membership[:start_date] = self.memberships.last[:start_date].to_s
  end
  
  def handle_empty_row
    add_membership_to_memberships if !self.current_membership[:name].blank?
    self.in_membership_set = false
  end
  
  def has_dates?(data)
    (!data[:date_of_birth].blank?) or (!data[:date_of_death].blank?)
  end
  
  def handle_consecutive_membership
    if current_member_same_constituency? 
      if self.memberships.last[:end_date].blank?
        self.memberships.last[:end_date] = self.current_membership[:start_date]
      end
      if set_date = self.memberships.last[:set]
        index = self.memberships.size - 1
        while is_set_member?(self.memberships.last, self.memberships[index]) and index >= 0
          if self.memberships[index][:end_date].blank?
            self.memberships[index][:end_date] = self.current_membership[:start_date]
          end
          index -= 1
        end
      end
    end
  end
  
  def is_set_member?(membership, other)
    other[:set] and other[:set] == membership[:set] and membership[:constituency] == other[:constituency]
  end
  
  def handle_concurrent_membership
    self.memberships.last[:set] = self.memberships.last[:start_date]
    self.current_membership[:set] = self.current_membership[:start_date]
  end
  
  def add_membership_to_memberships
    clean_current_membership_name
    add_name_parts(self.current_membership)
    parse_current_membership_date(:start_date)
    parse_current_membership_date(:date_of_birth)
    parse_current_membership_date(:date_of_death)
    parse_current_membership_date(:end_date)
    if self.in_membership_set
      handle_concurrent_membership
    else
      handle_consecutive_membership 
    end
    self.memberships << self.current_membership
    if !self.current_constituency_start_date 
      self.current_constituency_start_date = self.current_membership[:start_date]
    end
    self.current_membership = new_membership
    self.in_membership_set = true
  end
  
  def current_member_same_constituency?
    if self.memberships.last 
      return true if self.memberships.last[:constituency] == self.current_membership[:constituency]
    end
    return false
  end
  
  def clean_current_membership_name
    year_end_pattern = /\s*\(to\s(\d?\d?\s?\S\S\S)?\s*(\d\d\d\d)\)/
    self.current_membership[:name] = self.current_membership[:name].gsub(/\sFor\s.*/, '').strip
    self.current_membership[:name] = self.current_membership[:name].gsub(/\s\[.*/, '').strip
    if year_end_match = year_end_pattern.match(self.current_membership[:name])
      self.current_membership[:name] = self.current_membership[:name].gsub(year_end_pattern, '')
      if year_end_match[1]
        begin
          date = Date.parse("#{year_end_match[1]} #{year_end_match[2]}")
          if date.day == 1
            date = Date.new(date.year, date.month+1, 1) - 1
          end
          self.current_membership[:end_date] = date.to_s
        rescue
          self.current_membership[:end_date] = date_for_year(year_end_match[2].to_i).to_s
        end
      else  
        self.current_membership[:end_date] = date_for_year(year_end_match[2].to_i).to_s
      end
    end
  end

  def parse_current_membership_date(attribute)
    date_value = to_date(self.current_membership[attribute])
    year_value = nil
    if ! date_value and year_match = /(\d\d\d\d)/.match(current_membership[attribute])
      year_value = year_match[1].to_i
    end
    self.current_membership[attribute] = date_value
    if attribute == :date_of_birth and year_value
      self.current_membership[:year_of_birth] = year_value
    elsif attribute == :date_of_death and year_value
      self.current_membership[:year_of_death] = year_value
    end
  end
  
  def row_data(row)
    cell_contents = row.search('td').map{ |cell| clean_element_contents(cell) }
    { :start_date => cell_contents[0], 
      :name => cell_contents[2], 
      :date_of_birth => cell_contents[3],
      :date_of_death => cell_contents[4] }
  end
  
  def add_membership_data_from_row(row)
    row_data = row_data(row)
    self.current_membership[:start_date] += " #{row_data[:start_date]}"
    self.current_membership[:name] += " #{row_data[:name]}"
    self.current_membership[:name] = self.current_membership[:name].split.join(' ')
    self.current_membership[:date_of_birth] += " #{row_data[:date_of_birth]}"
    self.current_membership[:date_of_death] += " #{row_data[:date_of_death]}"
    self.current_membership[:constituency] = self.current_constituency
    
  end
  
  def add_name_parts(attributes)
    attributes[:firstname] = ''
    attributes[:lastname] = ''
    name = attributes[:name].split(',').first
    return false unless name
    name = name.split('(').first.strip
    attributes[:firstname] = Hansard::CommonsMembershipParser.find_firstname(name)
    attributes[:lastname] = Hansard::CommonsMembershipParser.find_lastname(name)
    attributes[:honorific] = Hansard::CommonsMembershipParser.find_honorific(name)
    firstnames_patt = regexp "(#{attributes[:firstname]}.*?)#{attributes[:lastname]}"
    if firstnames_match = firstnames_patt.match(name)
      attributes[:firstnames] = firstnames_match[1].strip
    end
    return true
  end
  
  def new_membership
    {:start_date => '', 
     :end_date => '', 
     :name => '', 
     :date_of_birth => '', 
     :year_of_birth => nil, 
     :date_of_death => '', 
     :year_of_death => nil,
     :constituency => ''}
  end
  
  def constituency_cell(row)
    self.constituency_classes.each do |class_name|
      constituency_cell = row.at("td#{class_name}")
      return constituency_cell if constituency_cell
    end
    return nil
  end
  
  def constituency_end_cell(row)
    self.constituency_end_classes.each do |class_name|
      constituency_end_cell = row.at("td#{class_name}")
      return constituency_end_cell if constituency_end_cell
    end
    return nil
  end
  
  def constituency_text(row)
    constituency_cell = constituency_cell(row)
    return clean_element_contents(constituency_cell) if constituency_cell
    return nil
  end
  
  def constituency_end_text(row)
    constituency_end = constituency_end_cell(row)
    return clean_element_contents(constituency_end) if constituency_end
    return nil
  end
  
  def clean_element_contents(element)
    text = element.inner_text.gsub("\240", '')  
    text = text.gsub("\r\n", "\n")
    text = text.split.join(' ').strip
  end
  
  def empty_row? row
    return true if row.search('td').map{ |cell| cell.inner_text }.join.strip.empty?
    return false
  end
  
  def to_date(string)
    begin 
      Date.parse(string)
    rescue
      return nil
    end
  end

  def constituency_matches
    @constituency_matches ||= load_constituency_matches
  end
  
  def load_constituency_matches
    @constituency_matches = {} unless @constituency_matches
    File.new(CONSTITUENCY_MATCH_FILE).each do |line|
      parse_constituency_match_line(line)
    end
    @constituency_matches
  end
  
  def parse_constituency_match_line(line)
    d = line.split("\t")
    atts = { :name  => d[0],
             :start_year => d[1].blank? ? nil : d[1].to_i,
             :end_year => d[2].blank? ? nil : d[2].to_i,
             :import_id  => d[4].to_i}
    @constituency_matches[[atts[:name], atts[:start_year], atts[:end_year]]] = atts[:import_id]
  end
  
  def mode(array)
    h, max = array.inject(Hash.new(0)) {|h, i| h[i] += 1; h}, h.values.max
    h.select {|k, v| v == max}.transpose.first
  end
  
  def save_constituency_matches
    next_id = last_constituency_id + 1
    open(NEW_CONSTITUENCIES_FILE, 'a') do |new_constituency_file|  
      open(CONSTITUENCY_MATCH_FILE, 'a') do |match_file|   
        write_constituency_records(new_constituency_file, match_file, next_id)
      end
    end
  end
  
  def write_constituency_records(new_constituency_file, match_file, next_id)
    self.constituencies.each do |constituency_info, matches|
      name, start_date, end_date = constituency_info
      start_year = start_date ? start_date.year : nil
      end_year = end_date ? end_date.year : nil
      atts = [name, start_year, end_year]
      matches = exclude_compass_mismatches(name, matches)
      next if start_year and start_year > LAST_LOAD_YEAR
      if matches.empty? or (end_year and end_year <= FIRST_YEAR_OF_EXISTING_DATA)
        atts += [name.titlecase, next_id]
        if !end_year or end_year > FIRST_YEAR_OF_EXISTING_DATA
          next
        end
        name = name.gsub('(', '[').gsub(')', ']')
        new_constituency_file.write("#{next_id}\t#{name.titlecase}\t#{start_year}\t#{end_year}\n")
        next_id += 1
      else  
        if matches.uniq.size > 1
          next
        end
        most_common = matches.first
        if start_year and start_year >= FIRST_YEAR_OF_EXISTING_DATA and most_common.start_year != start_year
          next
        end
        atts += [most_common.name,most_common.import_id]     
      end
      
      match_file.write("#{atts.join("\t")}\n")
    end
  end
  
  def exclude_compass_mismatches(name, matches)
    filtered_matches = []
    compass_directions = ['north', 'south', 'east', 'west']
    matches.each do |match|
      mismatch = false
      compass_directions.each do |direction|
        if name.downcase.index(direction) and !match.name.downcase.index(direction)
          mismatch = true
        elsif match.name.downcase.index(direction) and !name.downcase.index(direction)
          mismatch = true
        end
      end
      filtered_matches << match unless mismatch
    end
    filtered_matches
  end
  
  def last_constituency_id
    last_id(NEW_CONSTITUENCIES_FILE)
  end
  
  def calculate_constituency_matches
    parse unless self.parsed
    self.memberships.each do |membership|
      add_constituency_match_from_parsed_membership(membership)
    end
    self.constituencies.each do |constituency, matches|
      name, start_date, end_date = constituency 
      constituency_hash = {:name => name, 
                           :end_date => end_date}
      constituency_hash[:start_date] = start_date if start_date and start_date > Date.new(1833, 1, 1)
      name_and_year_matches = Constituency.find_by_name_and_years(constituency_hash)
      if name_and_year_matches.empty?
        attributes = {:name => clean_constituency_name(constituency_hash[:name]), 
                      :start_date => constituency_hash[:start_date], 
                      :end_date => constituency_hash[:end_date]}
        name_and_year_matches = Constituency.find_by_name_and_years(attributes)
      end
      
      name_and_year_matches.each do |match|
        self.constituencies[constituency] << match
      end
    end
    self.constituencies
  end
  
  def clean_constituency_name(name)
    name = name.split('(').first
    name = name.gsub('&', 'and')
    name = name.gsub(/ COUNTY/, '')
    name = name.gsub(/ NORTH$/, ' NORTHERN')
    name = name.gsub(/ SOUTH$/, ' SOUTHERN')
    name = name.gsub(/ EAST$/, ' EASTERN')
    name = name.gsub(/ WEST$/, ' WESTERN')
    name = name.gsub('NORTHEAST', 'NORTH EAST')
    name = name.gsub('NORTHWEST', 'NORTH WEST')
    name = name.gsub('SOUTHEAST', 'SOUTH EAST')
    name = name.gsub('SOUTHWEST', 'SOUTH WEST')
    name = name.gsub('NORTH-EAST', 'NORTH EASTERN')
    name = name.gsub('NORTH-WEST', 'NORTH WESTERN')
    name = name.gsub('SOUTH-EAST', 'SOUTH EASTERN')
    name = name.gsub('SOUTH-WEST', 'SOUTH WESTERN')
    name = name.strip
  end
  
  def add_constituency_match_from_parsed_membership(membership)
    people = match_people(membership)
    people.each do |person|
      person.commons_memberships.each do |existing_membership|
        next unless existing_membership.match_by_year(membership)  and existing_membership.start_date.year < 1920
        self.constituencies.keys.each do |constituency_key|
          if match_constituency(constituency_key, existing_membership)
            self.constituencies[constituency_key] << existing_membership.constituency  
          end
        end
      end
    end
  end
  
  def fuzzy_name_match name_one, name_two
    match = name_one.downcase.index(name_two.split.first.downcase) 
    return true if match
    match = name_two.downcase.index(name_one.split.first.downcase) 
    return true if match 
    return false
  end
  
  def match_constituency(constituency_key, membership)
    constituency_name = constituency_key[0]
    start_date = constituency_key[1]
    end_date = constituency_key[2]

    return false unless fuzzy_name_match(constituency_name, membership.constituency.name)
    return false if end_date and membership.start_date > end_date
    return false if start_date and membership.end_date and membership.end_date < start_date
    return true
  end
  
  def match_people(membership_data)
    people = Person.find_all_by_names_and_years(membership_data)
  end

end