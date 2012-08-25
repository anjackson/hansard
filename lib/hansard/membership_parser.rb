class Hansard::MembershipParser
  
  PEOPLE_FILE = "#{RAILS_ROOT}/reference_data/commons_library_data/people.txt"
  LORDS_MEMBERSHIPS_FILE = "#{RAILS_ROOT}/reference_data/commons_library_data/lords_memberships.txt"
  ALTERNATIVE_TITLES_FILE = "#{RAILS_ROOT}/reference_data/commons_library_data/alternative_titles.txt"
  attr_reader :new_people, :new_memberships, :new_alternative_titles
  attr_accessor :matches_by_membership
  
  include Acts::StringNormalizer
  acts_as_string_normalizer
  
  def hereditary_peers_abolition_date
    @@hereditary_peers_abolition_date ||= Date.new(1999, 11, 11)
  end
  
  def peerage_act_1963_date
    @@peerage_act_1963_date ||= Date.new(1963, 7, 31)
  end
  
  def last_people_id
    last_id(PEOPLE_FILE)
  end
  
  def last_id(file)
    last_line = open(file).readlines.last
    if !last_line
      last_id = 0
    else
      last_id = last_line.split("\t")[0].to_i
    end
    last_id
  end
  
  def last_lords_membership_id
    last_id(LORDS_MEMBERSHIPS_FILE)
  end
  
  def last_alternative_title_id
    last_id(ALTERNATIVE_TITLES_FILE)
  end
  
  def match_person(membership)
    (Person.match_person_exact(membership) or Person.match_person_loose(membership))
  end
  
  def hash_of_lists
    Hash.new{ |hash, key| hash[key] = [] }
  end
  
  def add_to_new_people(membership)
    new_people[membership[:person_import_id]] << membership
  end
  
  def add_to_new_memberships(membership, person)
    new_memberships[person.import_id] << membership
  end
  
  def save_memberships(memberships, save_people=false)
    memberships.each do |person_import_id, membership_list|
      person_import_id = save_person(membership_list.first) if save_people
      membership_list.each do |membership|
        save_membership(membership, person_import_id)
      end
    end
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
  
  def save_person(person)
    next_id = last_person_id + 1
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
  
  def add_to_alternative_titles(membership)
    import_id = membership[:person_import_id]
    unless new_alternative_titles[import_id].include? membership
      new_alternative_titles[import_id] << membership 
    end
  end
  
end