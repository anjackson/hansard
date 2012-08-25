class Hansard::PeeragesParser < Hansard::MembershipParser
  
  attr_accessor :base_host, :peerage_type
  
  EARLIEST_BIRTH_YEAR_EXPECTED_WITHOUT_DEATH = 1910
    
  def initialize 
    @files = ['index_baron.htm', 
              'index_baron_by_writ.htm', 
              'index_duke.htm', 
              'index_earl.htm', 
              'index_marquess.htm', 
              'index_viscount.htm',
              'index_life_peer.htm',
              'index_law_lord.htm'
              ]
    @base_host = 'www.thepeerage.com'
    @matches_by_membership = {}
    @new_people = hash_of_lists
    @new_memberships = hash_of_lists
    @new_alternative_titles = hash_of_lists
  end
  
  def parse
    @files.each do |file|
      path = "#{RAILS_ROOT}/reference_data/www.thepeerage.com/#{file}"
      puts "Parsing #{file}"
      parse_file(path)
    end
    save_memberships(new_people, save_people=true)
    save_memberships(new_memberships, save_people=false)
    save_alternative_titles
    return true
  end
  
  def save_alternative_titles
    new_alternative_titles.each do |person_import_id, alternative_titles|
      next_id = last_alternative_title_id + 1
      open(ALTERNATIVE_TITLES_FILE, 'a') do |alternative_titles_file| 
        alternative_titles.each do |alternative_title|
          attributes = [next_id, 
                        person_import_id, 
                        alternative_title[:number], 
                        alternative_title[:degree], 
                        alternative_title[:title], 
                        nil,
                        alternative_title[:title_type],
                        alternative_title[:start_date].year,
                        alternative_title[:start_date],
                        alternative_title[:end_date] ? alternative_title[:end_date].year : nil,
                        alternative_title[:end_date]]
          alternative_titles_file.write "#{attributes.join("\t")}\n"
          next_id += 1
        end
      end
    end
  end
  
  def parse_file(file)
    filename = File.basename(file)
    if filename == 'index_life_peer.htm'  
      @peerage_type = 'Life peer'
    elsif filename == 'index_law_lord.htm'
      @peerage_type = 'Law Lord'
    else
      @peerage_type = 'Hereditary'
    end
    doc = open_doc(file)
    parse_memberships(doc)
    return true
  end
  
  def open_doc(file)
    Hpricot(open(file).read)
  end
  
  def parse_memberships(doc)
    paras = doc.search('p')
    paras.each do |para|
      title = para.at('b')
      if title
        text = para.inner_html.split("\r\n").join
        lines = text.split('<br />')
        get_memberships(lines)
      end
    end
  end
  
  def get_memberships(lines)
    title_attributes = parse_title_and_holders(lines)
    title_attributes = filter_for_dates(title_attributes)
    title_attributes[:memberships].each do |membership|
      person_attributes = get_person_details(membership)
      membership = membership.merge(person_attributes)
      handle_membership(membership, title_attributes)
    end
    
  end
  
  def handle_membership(membership, title_attributes)
    year_of_birth = membership[:date_of_birth] ? membership[:date_of_birth].year : membership[:year_of_birth]
    if !year_of_birth or year_of_birth < EARLIEST_BIRTH_YEAR_EXPECTED_WITHOUT_DEATH
      return unless membership[:year_of_death] or membership[:date_of_death] 
    end
    
    return if matches_by_membership[membership[:person_import_id]]
    return if title_attributes[:title].start_with? 'Baronet'
    membership = get_degree_and_title(membership, title_attributes[:title])        
    person = match_person(membership)
    
    if person 
      membership[:person_import_id] = person.import_id
    end    
    return unless person_sits_in_lords?(membership)
    return unless region_sits_in_lords?(membership, title_attributes)
    
    if person

      if person.lords_memberships.empty? or ! person.lords_memberships.find_by_years_degree_and_title(membership)
    
        add_to_new_memberships(membership, person)
      
      end
      
    else
      if LordsMembership.find_by_years_degree_and_title(membership) 
        matches_by_membership[membership[:person_import_id]] = true
      else
        add_to_new_people(membership) 
      end
    end
  end
  
  def save_person(person)
    open(PEOPLE_FILE, 'a') do |people_file| 
      attributes = [person[:person_import_id], 
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
    person[:person_import_id]
  end
  
  def clean_person_import_id(import_id)
    import_id = /\d+/.match(import_id)
    import_id = 10000000 + (import_id[0].to_i)
  end
  
  def save_membership(membership, import_id)
    next_id = last_lords_membership_id + 1
    open(LORDS_MEMBERSHIPS_FILE, 'a') do |membership_file|   
      attributes = [next_id, 
                    import_id, 
                    membership[:number], 
                    membership[:degree], 
                    membership[:title], 
                    nil,
                    membership[:peerage_type],
                    membership[:start_date].year,
                    membership[:start_date],
                    membership[:end_date] ? membership[:end_date].year : nil,
                    membership[:end_date]]

       membership_file.write "#{attributes.join("\t")}\n"
    end  
  end
  
  def get_degree_and_title(membership, title)
    degree = Hansard::PeeragesParser.find_title_degree(title)
    membership[:degree] = Hansard::PeeragesParser.correct_degree_for_gender(degree, membership[:gender])
    membership[:title] = Hansard::PeeragesParser.title_without_degree(title)
    membership
  end
  
  def get_person_details(membership)
    page, anchor = membership[:url].split('#')
    path = get_local_file(page)
    person_attributes = parse_person_page(path, anchor)
  end
  
  def parse_person_page(path, anchor)
    contents = open(path)
    doc = Hpricot(contents)
    person_div = doc.at("div.itp##{anchor}")
    biographical_info = person_div.at('div.sinfo').inner_html
    person_attributes = parse_biographical_info(biographical_info)
  end
  
  def parse_biographical_info(bio_string)
    bio_pattern = /(M|F), #\d+(, b\. (\d\d? .*? \d\d\d\d))?(, d\. (\d\d? .*? \d\d\d\d))?/
    match = bio_pattern.match(bio_string)
    biographical_attributes = { :gender => match[1],
                                :date_of_birth => match[3].blank? ? nil : Date.parse(match[3]), 
                                :date_of_death => match[5].blank? ? nil : Date.parse(match[5]) }
    
    if !biographical_attributes[:date_of_death]
      death_year_pattern = /d\. (\d\d\d\d)/
      if match = death_year_pattern.match(bio_string)
        biographical_attributes[:year_of_death] = match[1].to_i
      end
      biographical_attributes[:estimated_date_of_death] = true
    else
      biographical_attributes[:estimated_date_of_death] = false
    end
    if !biographical_attributes[:date_of_birth]
      birth_year_pattern = /b\. (\d\d\d\d)/
      if match = birth_year_pattern.match(bio_string)
        biographical_attributes[:year_of_birth] = match[1].to_i
      end
      biographical_attributes[:estimated_date_of_birth] = true
    else
      biographical_attributes[:estimated_date_of_birth] = false
    end
    biographical_attributes
  end
  
  def get_local_file(page)
    request_path = "/#{page}"
    local_path = "#{RAILS_ROOT}/reference_data/#{base_host}#{request_path}"
    local_file = File.exist?(local_path)
    if !local_file
      body = nil
      puts "getting #{request_path}"

      begin
        Net::HTTP.start(base_host, 80) do |http|
         response, body =  http.get(request_path)  
        end  
      rescue
        sleep(15 + rand(10))
        Net::HTTP.start(base_host, 80) do |http|
          response, body =  http.get(request_path)
        end
      end

      f = File.open(local_path, 'w')
      f.write(body)
      f.close
      sleep(15 + rand(10))
    end
    local_path
  end
  
  def filter_for_dates(attributes)
    attributes[:memberships] = attributes[:memberships].select do |membership|
      (membership[:end_date].nil? or membership[:end_date] >= FIRST_DATE) && membership[:start_date] && membership[:start_date] <= LAST_DATE 
    end
    attributes
  end
  
  def parse_title_and_holders(lines)
    attributes = parse_title(lines.shift)
    lines.each do |line|
      break if /A total of/.match line
      membership = parse_membership_line(line, attributes)
      attributes[:memberships] << membership if membership
    end
    attributes
  end
  
  def region_sits_in_lords?(membership, attributes)
    return true if membership[:peerage_type] == 'Life peer'
    return true if membership[:peerage_type] == 'Law Lord'
    region = attributes[:region]
    return true if region == 'United Kingdom'
    return true if region == 'Great Britain'
    return true if region == 'England'
    original_membership = membership.clone
    if region == 'Ireland'
      add_to_alternative_titles(original_membership)
      return false
    end
    if region == 'Scotland'
      if membership[:end_date].blank? or membership[:end_date] > peerage_act_1963_date
        if membership[:start_date] < peerage_act_1963_date
          add_to_alternative_titles(original_membership)
          membership[:start_date] = peerage_act_1963_date
        end
        return true
      else
        add_to_alternative_titles(original_membership)
        return false
      end
    end
    raise "Unexpected region: #{region}"
  end
  
  def person_sits_in_lords?(membership)
    raise 'Gender of this person is not known' unless ['M', 'F'].include? membership[:gender]
    return true if membership[:peerage_type] == 'Life peer'
    return true if membership[:peerage_type] == 'Law Lord'
    return false if ! membership[:start_date]
    original_membership = membership.clone
    if membership[:start_date] > hereditary_peers_abolition_date
      add_to_alternative_titles(original_membership)
      return false 
    end
    if membership[:end_date].blank? or membership[:end_date] > hereditary_peers_abolition_date
      add_to_alternative_titles(original_membership)
      membership[:end_date] = hereditary_peers_abolition_date
    end
    return true if membership[:gender] == 'M'
    
    if membership[:end_date].blank? or membership[:end_date] > peerage_act_1963_date
      if membership[:start_date] < peerage_act_1963_date
        add_to_alternative_titles(original_membership)
        membership[:start_date] = peerage_act_1963_date
      end
      return true
    else
      add_to_alternative_titles(membership)
      return false
    end
  end
  
  def parse_membership_line(line, attributes)
    return nil if line.blank?
    membership_pattern = regexp('(?:&nbsp; ?)?(.*?):?&nbsp<a href="(.*)">(.*?)<\/a>(?: \((bt \d\d\d\d-\d\d\d\d|.*?)-(.*?)\))?')
    match = membership_pattern.match(line)
    name = match[3]
    names = name.split
    lastname = names.last
    firstname = names.first
    firstnames = names[0..names.size-2].join(' ')
    attributes = { :name => name, 
                   :firstname => firstname,
                   :lastname => lastname, 
                   :firstnames => firstnames,
                   :url => match[2], 
                   :number => match[1], 
                   :peerage_type => peerage_type, 
                   :title_type => "Peerage of #{attributes[:region]}",
                   :person_import_id => clean_person_import_id(match[2].split('#').last) }
    relevant_date_pattern = /(18\d\d|19\d\d|20\d\d)/
    if relevant_date_pattern.match(match[4]) or relevant_date_pattern.match(match[5])
      attributes = get_date_attributes(match[4], :start_date, attributes)
      attributes = get_date_attributes(match[5], :end_date, attributes)
      attributes
    else
      return nil
    end
  end
  
  def get_date_attributes(date_string, date_key, attributes)
    return attributes if date_string.blank? 
    estimation_key = "estimated_#{date_key}".to_sym
    letter_pattern = /^([a|b|c])? ?(\d\d\d\d)/
    between_pattern = /^bt ?(\d\d\d\d)-(\d\d\d\d)/
    
    if letter_match = letter_pattern.match(date_string)
      attributes = attributes_from_letter_match(letter_match, date_key, estimation_key, attributes)
    elsif between_match = between_pattern.match(date_string)
      attributes = attributes_from_interval_match(between_match, date_key, estimation_key, attributes)
    else
      attributes = attributes_from_date(date_string, date_key, estimation_key, attributes)
    end
    attributes
  end
  
  def attributes_from_interval_match(between_match, date_key, estimation_key, attributes)
    if date_key == :start_date
      attributes[date_key] = first_date(between_match[1])
    else
      attributes[date_key] = last_date(between_match[2])
    end
    attributes[estimation_key] = true
    attributes
  end
  
  def attributes_from_date(date_string, date_key, estimation_key, attributes)
    attributes[date_key] = Date.parse(date_string)
    if /^[c|a|b]/.match date_string
      attributes[estimation_key] = true
    else
      attributes[estimation_key] = false
    end
    attributes
  end
  
  def attributes_from_letter_match(letter_match, date_key, estimation_key, attributes)
    if letter_match[1] == 'b'
      attributes[date_key] = first_date(letter_match[2])
    elsif letter_match[1] == 'a'
      attributes[date_key] = last_date(letter_match[2])
    else
      if date_key == :start_date
        attributes[date_key] = first_date(letter_match[2])
      else
        attributes[date_key] = last_date(letter_match[2])
      end
    end
    attributes[estimation_key] = true
    attributes
  end
  
  def last_date(year_string)
     Date.new(year_string.to_i, 12, 31)
  end
  
  def first_date(year_string)
     Date.new(year_string.to_i, 1, 1)
  end
  
  def parse_title(title_line)
    title_line = title_line.gsub('&nbsp;', '')
    title_pattern = /<b>(.*?)<\/b>.*?\[(.*?), (\d\d\d\d)?.*?\]/
    match = title_pattern.match(title_line)
    { :title => match[1], 
      :region => match[2], 
      :date_created => match[3], 
      :memberships => [] }
  end
  
end