class Hansard::LordsMembershipParser < Hansard::MembershipParser
  
  attr_accessor :parsed

  def initialize file
    @file = file
  end
  
  def parse
    self.parsed = true
    memberships = parse_memberships
    memberships_by_person = memberships_by_person(memberships)
    memberships_by_person.each{ |person_id, memberships| save_data(memberships) }
  end
  
  def save_data(memberships)
    person = match_person(memberships.first)
    if !person
      import_id = save_person(memberships.first)
      person = Person.new(:import_id => import_id)
    end
    matched = false
    matched = true if !person.lords_memberships.empty?
    memberships.each do |membership|
      save_membership(membership, person) if !matched
    end
  end
  
  def memberships_by_person(memberships)
    memberships_by_person = Hash.new{ |hash, key| hash[key] = [] }
    memberships.each do |membership|
      unless memberships_by_person[membership[:import_id]].include? membership
        memberships_by_person[membership[:import_id]] << membership 
      end
    end
    memberships_by_person
  end
  
  def parse_memberships
    input = File.read(@file)
    input = Iconv.new('US-ASCII//TRANSLIT', 'UTF-16').iconv(input)
    memberships = []
    input.each_with_index do |line, index|
      next if index == 0
      attributes = parse_membership_line(line)
      next if ! attributes[:start_date]
      next if attributes[:start_date] > LAST_DATE
      next if attributes[:end_date] and attributes[:start_date] > attributes[:end_date]
      next if ! attributes[:date_of_birth]
      next if attributes[:start_date] > hereditary_peers_abolition_date and attributes[:peerage_type] == 'Hereditary'
      next if attributes[:firstname].blank? or attributes[:lastname].blank? or attributes[:title].blank?
      attributes[:degree], attributes[:title] = degree_and_title(attributes[:title])
      next if attributes[:degree].blank? or attributes[:title].blank?
      memberships << attributes
    end
    memberships
  end
  
  def save_person(person)
    next_id = last_people_id + 1
    open(PEOPLE_FILE, 'a') do |people_file| 
      attributes = [next_id, 
                 person[:firstnames], 
                 person[:firstname],
                 person[:lastname], 
                 person[:gender] == 'Female' ? 'Ms' : 'Mr',
                 person[:date_of_birth].year,
                 person[:date_of_birth], 
                 'TRUE',
                 person[:date_of_death] ? person[:date_of_death].year : nil,
                 person[:date_of_death], 
                 person[:date_of_death] ? 'TRUE': 'FALSE'
               ]
      people_file.write "#{attributes.join("\t")}\n"  
    end  
    next_id
  end
  

  
  def save_membership(membership, person)
    next_id = last_lords_membership_id + 1
    open(LORDS_MEMBERSHIPS_FILE, 'a') do |membership_file|   
      end_date = [membership[:end_date], membership[:retired_date]].compact.min
      attributes = [next_id, 
                    person.import_id, 
                    nil, 
                    membership[:degree], 
                    membership[:title], 
                    nil,
                    membership[:peerage_type],
                    membership[:start_date].year,
                    membership[:start_date],
                    end_date ? end_date.year : nil,
                    end_date]
                          
       membership_file.write "#{attributes.join("\t")}\n"
    end  
  end
  
  def degree_and_title(title)
    degree = nil
    title = strip_title_suffixes(title)
    title = strip_title_prefixes(title)

    if degree = self.class.find_title_degree(title)
      return [degree, title.gsub(/^#{degree}/, '').strip]
    end
    if honorific = self.class.find_honorific(title)
      return [honorific, title.gsub(/^#{honorific}/, '').strip]
    end 
    [degree, title]
  end
  
  def strip_title_suffixes(title)
    suffix_letters = /(\s+[A-Z]+,?(:?\s\(Can\.\))?)+$/
    title = title.gsub(suffix_letters, '')
    hereditary_suffix = /H1?$/
    title = title.gsub(hereditary_suffix, '')
  end
  
  def strip_title_prefixes(title)
    the = /(?:the\.?(?:\sthe)?)?/i
    prefix = /(?:
                His\sGrace
                  |
                HRH\sThe\sPrince\sEdward, 
                  |
                His\sRoyal\sHighness
                  | 
                Major(?:-General)?
                  |
                General
                  |
                The\sAdmiral\sof\sthe\sFleet
                  |
                Professor
                  | 
                the\sHon\.
                  |
                (?:#{the}
                  (?:\s?(?:Rt\.?|Most|Rev\.))\s*(?:Hon|Revd?|Canon)?\.?)?
                )?\s/x
    multi_prefix_pattern = /^(?:#{prefix}
                              (?:(?:and\s)?#{prefix})?
                             )?
                             (?:#{the}\s)?
                             (.*)/x
    if match = multi_prefix_pattern.match(title)
      title = match[1]
    end
    title
  end
  
  def parse_membership_line(line)
    d = line.split('","').map{ |item| strip_quotes(item) }
    attributes = {:import_id => d[0].to_i,
                  :lastname => d[1].gsub(/\(.*\)/, '').strip, 
                  :firstname => d[2], 
                  :firstnames => d[3], 
                  :title => d[4], 
                  :gender => d[5], 
                  :date_of_birth => parse_date(d[6]), 
                  :date_of_death => parse_date(d[8]),
                  :retired_date => parse_date(d[9]), 
                  :start_date => parse_date(d[10]), 
                  :end_date => parse_date(d[11]),
                  :peerage_type => parse_string(d[12])
      }
  end
  
  def strip_quotes string
    quotes = /"?(.*)"?/
    if match = quotes.match(string)
      string =  match[1].strip
    else
      string = string.strip
    end
    string
  end
  
  def parse_string string
    string.blank? ? nil : string
  end
  
  def parse_date date_string
    date_string.blank? ? nil : Date.parse(date_string)
  end
  
end