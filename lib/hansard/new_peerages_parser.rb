class Hansard::NewPeeragesParser < Hansard::MembershipParser

  PEERAGE_TYPES = {'A'   => 'Life peer', 
                   'H'   => 'Hereditary', 
                   'H:I' => 'Hereditary', 
                   'H:S' => 'Hereditary', 
                   'L'   => 'Life peer', 
                   'L:H' => 'Life peer', 
                   'P'   => 'Hereditary', 
                   'X'   => 'Hereditary'}
  
  DEGREES = {'L' => 'Baron', 
             'D' => 'Duke',
             'Dss' => 'Duchess',
             'M'  =>	'Marquess',
             'Mss' => 'Marchioness',
             'E' => 'Earl', 
             'C' =>	'Countess',
             'V' => 'Viscount',
             'Vss' => 'Viscountess',
             'B' => 'Baroness'}
  
  def initialize file
    @file = file
    @matches_by_membership = {}
    @new_people = hash_of_lists
    @new_memberships = hash_of_lists
    @new_alternative_titles = hash_of_lists
  end
  
  def parse
    memberships = parse_memberships
    return true
  end
  
  def parse_memberships
    doc = Hpricot(open(@file).read)
    peerages = doc.at('table')
    rows = peerages.search('tr')
    rows.each do |row|
      membership =  membership_from_row(row)
      handle_membership(membership) if membership 
    end
    save_memberships(new_people, save_people=true)
    save_memberships(new_memberships, save_people=false)
  end
  
  def handle_membership(membership)
    return unless membership[:date_of_death] 
    person = match_person(membership)
    return unless person_sits_in_lords?(membership)
    if person
      membership[:person_import_id] = person.import_id
      if person.lords_memberships.empty? or ! person.lords_memberships.find_by_years_degree_and_title(membership)
        add_to_new_memberships(membership, person)
      end
    else
      if !LordsMembership.find_by_years_degree_and_title(membership) 
        add_to_new_people(membership) 
      end
    end
  end
  
  def strings_from_row(row)
    cells = row.search('td')
    date_string = cells.first.at('a').inner_text
    peerage_string = cells.last.inner_html
    [date_string, peerage_string]
  end
  
  def membership_from_row(row)
    date_string, peerage_string = strings_from_row(row)
    date_attributes = get_info_from_date_string(date_string)
    return nil if date_attributes[:start_date] >= LAST_DATE
    peerage_attributes = get_info_from_peerage_string(peerage_string)
    return nil if !peerage_attributes[:date_of_death]
    {:title => peerage_attributes[:title], 
     :start_date => date_attributes[:start_date], 
     :date_of_death => peerage_attributes[:date_of_death],
     :end_date => peerage_attributes[:date_of_death],
     :firstname => peerage_attributes[:firstname],
     :firstnames => peerage_attributes[:firstnames],  
     :lastname => peerage_attributes[:lastname], 
     :degree => peerage_attributes[:degree],
     :peerage_type => date_attributes[:peerage_type],
     :gender => gender_from_degree(peerage_attributes[:degree])}
  end

  def gender_from_degree(degree)
    case degree
    when 'Baron', 'Duke', 'Marquess', 'Viscount', 'Earl'
      'M'
    when 'Duchess', 'Marchioness', 'Countess', 'Viscountess', 'Baroness'
      'F'
    end
  end
  
  def save_person(person)
    next_id = last_people_id + 1
    open(PEOPLE_FILE, 'a') do |people_file| 
      attributes = [next_id, 
                 person[:firstnames], 
                 person[:firstname],
                 person[:lastname], 
                 person[:gender] == 'F' ? 'Ms' : 'Mr',
                 person[:date_of_birth].blank? ? person[:year_of_birth] : person[:date_of_birth].year,
                 person[:date_of_birth], 
                 person[:estimated_date_of_birth] ? 'FALSE' : 'TRUE',
                 person[:date_of_death].blank? ? person[:year_of_death] : person[:date_of_death].year,
                 person[:date_of_death], 
                 person[:estimated_date_of_death] ? 'FALSE' : 'TRUE'
               ]
      people_file.write "#{attributes.join("\t")}\n"  
    end  
    next_id
  end
  
  def add_to_new_people(membership)
    new_people[[membership[:firstname],
               membership[:firstnames], 
               membership[:lastnames], 
               membership[:date_of_death]]] << membership
  end
  
  def get_info_from_peerage_string(peerage_string)
    peerage_attributes = {}
    peerage_cell_pattern = /^(#{DEGREES.keys.join("|")})\.?\s       # L. 
                             (?:of\s*)?                             # of
                             <b>(.*?)<\/b>                          # <b>Gordon of Drumearn<\/b> 
                             .*?\s                                  # in the County of Stirling 
                             &\#8211;\s                             # &#8211; 
                             (.*?)                                  # Edward 
                             (\s.*?|\s)?                            # Strathearn 
                             (?:<i>                                 # <i>
                             (.*?)                                  # Gordon
                             <\/i>\s)?                              # <\/i> 
                             (?:\(.*\)\s)?                          # (1st L. Clive) 
                             \((?:died\s|extinct\(1\)\s)            # (died 
                             (\d\d?\s\S+\s\d\d\d\d)/x               # 21 Aug 1879
                            
    if match = peerage_cell_pattern.match(peerage_string)
      peerage_attributes[:degree] = DEGREES[match[1]]
      peerage_attributes[:title] = match[2]
      peerage_attributes[:firstname] = match[3]
      peerage_attributes[:firstnames] = (match[3] + match[4]).strip
      peerage_attributes[:lastname] = match[5]
      peerage_attributes[:date_of_death] = Date.parse(match[6])
    end
    peerage_attributes
  end
  
  def get_info_from_date_string(date_string)
    date_attributes = {}
    date_cell_pattern = /(\d\d? .*? \d\d\d\d) (?:\(.*\) )?\((.*?)\)/
    if match = date_cell_pattern.match(date_string)
      date_attributes[:start_date] = Date.parse(match[1])
      date_attributes[:peerage_type] = PEERAGE_TYPES[match[2]]
    end
    date_attributes
  end
  
end
