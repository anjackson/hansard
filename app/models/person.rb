class Person < ActiveRecord::Base
  
  has_many :commons_memberships
  has_many :lords_memberships
  has_many :commons_contributions, :through => :commons_memberships
  has_many :lords_contributions, :through => :lords_memberships
  has_many :constituencies, :through => :commons_memberships
  has_many :office_holders
  has_many :offices, :through => :office_holders
  has_many :alternative_names
  has_many :alternative_titles
  has_and_belongs_to_many :sittings, :uniq => true
  before_validation_on_create :populate_slug
  acts_as_slugged
  acts_as_string_normalizer 
  acts_as_id_finder
  validates_uniqueness_of :slug

  def self.json_defaults
    includes = {:commons_memberships => {:except => CommonsMembership.id_attributes, 
                                         :include => {:constituency => 
                                                       {:except => Constituency.id_attributes}}},
                :office_holders => {:except => OfficeHolder.id_attributes,
                                    :include => {:office => 
                                                  {:except => Office.id_attributes}}}}
    {:except => id_attributes, 
     :include => includes }
  end
  
  def self.find_with_concurrent_memberships
    find_by_sql('SELECT distinct people.* 
                 FROM commons_memberships a, commons_memberships b, people 
                 WHERE people.id = a.person_id 
                 AND a.person_id = b.person_id 
                 AND a.start_date < b.end_date 
                 AND a.end_date > b.start_date
                 AND a.id > b.id')
  end
  
  def self.find_with_multiple_lastnames
    @multiple_names ||= find(:all, :conditions => ["lastname like ?", '% %'])
  end  
 
  def self.missing?(attributes, match = :strict)
    lastname = attributes[:lastname]
    year_of_birth = year_from_attributes(attributes, :birth)
    year_of_death = year_from_attributes(attributes, :death)
    return false unless lastname and year_of_birth and year_of_death
    name_conditions = {:conditions => ["lastname = ?", lastname]}
    if match == :loose
      firstname = attributes[:firstname]
      return false unless firstname 
      name_conditions = {:conditions => ["firstname = ? and lastname = ?", firstname, lastname]}
    end
    people = find(:all, name_conditions)
    return false if !people.empty?
    alternative_names = AlternativeName.find(:all, name_conditions)
    return false if !alternative_names.empty?
    years = find(:all, :conditions => ['YEAR(date_of_birth) = ? and YEAR(date_of_death) = ?', year_of_birth, year_of_death])
    return false if !years.empty?
    return true
  end
  
  def self.match_person_exact(membership)
    if membership[:date_of_death]
      people = Person.find_all_by_name_birth_year_and_date_of_death(membership)
    else
      people = Person.find_all_by_name_birth_year_and_no_date_of_death(membership)
    end
    return people.first if people.size == 1
    people = Person.find_all_by_name_and_date_of_death_exact(membership)
    return people.first if people.size == 1
    people = Person.find_all_by_name_and_date_of_birth_exact(membership)
    return people.first if people.size == 1   
    people = Person.find_all_by_lastname_date_of_birth_exact_and_date_of_death_exact(membership)
    return people.first if people.size == 1
    return nil
  end
  
  def self.match_person_loose(membership)
    people = Person.find_all_by_name_birth_and_death_years_estimated(membership)
    return people.first if people.size == 1
    people = Person.find_all_by_name_and_death_year_estimated(membership)
    return people.first if people.size == 1
    people = Person.find_all_by_name_and_birth_year_estimated(membership)
    return people.first if people.size == 1
    return nil
  end
  
  def self.year_from_attributes(attributes, year)
    if year == :birth
      (attributes[:date_of_birth].year if attributes[:date_of_birth]) || attributes[:year_of_birth]
    elsif year == :death
      (attributes[:date_of_death].year if attributes[:date_of_death]) || attributes[:year_of_death]    
    end
  end
  
  def self.find_all_by_name_birth_year_and_date_of_death(attributes)
    year_of_birth = year_from_attributes(attributes, :birth)
    date_of_death = attributes[:date_of_death]
    firstname = attributes[:firstname]
    lastname = attributes[:lastname]
    return [] unless year_of_birth and date_of_death
    date_param_string = "YEAR(people.date_of_birth) = ? and 
                         people.date_of_death = ?"
    date_params = [year_of_birth, date_of_death]
    find_by_name_and_other_criteria(attributes, date_param_string, date_params)  
  end
  
  def self.find_all_by_name_birth_year_and_no_date_of_death(attributes)
    year_of_birth = year_from_attributes(attributes, :birth)
    firstname = attributes[:firstname]
    lastname = attributes[:lastname]
    return [] unless year_of_birth
    date_param_string = "YEAR(people.date_of_birth) = ? and 
                         people.date_of_death is NULL"
    date_params = [year_of_birth]
    find_by_name_and_other_criteria(attributes, date_param_string, date_params)
  end

  def self.find_all_by_name_and_date_of_death_exact(attributes)
    date_of_death = attributes[:date_of_death]
    year_of_birth = year_from_attributes(attributes, :birth)
    return [] unless date_of_death
    date_param_string = "(people.date_of_death = ? or people.date_of_death = ? or people.date_of_death = ?) and 
                         people.estimated_date_of_death = ?"
    date_params = [date_of_death, date_of_death + 1, date_of_death - 1, false]
    people = find_by_name_and_other_criteria(attributes, date_param_string, date_params)
    people = filter_for_year_of_birth(people, year_of_birth) if year_of_birth
    people
  end
  
  def self.find_all_by_name_and_date_of_birth_exact(attributes)
    date_of_birth = attributes[:date_of_birth]
    year_of_death = year_from_attributes(attributes, :death)
    return [] unless date_of_birth
    date_param_string = "people.date_of_birth = ? and 
                         people.estimated_date_of_birth = ?"
    date_params = [date_of_birth, false]
    people = find_by_name_and_other_criteria(attributes, date_param_string, date_params)
    people = filter_for_year_of_death(people, year_of_death) if year_of_death
    people
  end
  
  def self.find_all_by_lastname_date_of_birth_exact_and_date_of_death_exact(attributes)
    date_of_birth = attributes[:date_of_birth]
    date_of_death = attributes[:date_of_death]
    lastname = attributes[:lastname]
    return [] unless date_of_birth 
    if date_of_death
      date_param_string = "people.date_of_birth = ? and 
                          people.estimated_date_of_birth = ? and
                          people.date_of_death = ? and 
                          people.estimated_date_of_death = ?"
      date_params = [date_of_birth, false, date_of_death, false]
    else
      date_param_string = "people.date_of_birth = ? and 
                          people.estimated_date_of_birth = ? and
                          people.date_of_death is NULL"
      date_params = [date_of_birth, false]
    end
    people = find_by_name_and_other_criteria(attributes, date_param_string, date_params, require_firstnames=false)
  end
  
  def self.filter_for_year_of_birth(people, year_of_birth)
    people = people.select do |person|
      (!person.date_of_birth) or (person.date_of_birth.year == year_of_birth)
    end
  end
  
  def self.filter_for_year_of_death(people, year_of_death)
    people = people.select do |person|
      (!person.date_of_death) or (person.date_of_death.year == year_of_death)
    end
  end
  
  def self.find_all_by_name_and_death_year_estimated(attributes)
    year_of_birth = year_from_attributes(attributes, :birth)
    year_of_death = year_from_attributes(attributes, :death)
    return [] unless year_of_death
    date_param_string = "YEAR(people.date_of_death) = ? and 
                         people.estimated_date_of_death = ?"
    date_params = [year_of_death, true]
    people = find_by_name_and_other_criteria(attributes, date_param_string, date_params)
    people = filter_for_year_of_birth(people, year_of_birth) if year_of_birth
    people
  end
  
  def self.find_all_by_name_and_birth_year_estimated(attributes)
    year_of_birth = year_from_attributes(attributes, :birth)
    year_of_death = year_from_attributes(attributes, :death)
    return [] unless year_of_birth
    date_param_string = "YEAR(people.date_of_birth) = ? and 
                         people.estimated_date_of_birth = ?"
    date_params = [year_of_birth, true]
    people = find_by_name_and_other_criteria(attributes, date_param_string, date_params)
    people = filter_for_year_of_death(people, year_of_death) if year_of_death
    people
  end
  
  def self.find_all_by_name_birth_and_death_years_estimated(attributes)
    year_of_birth = year_from_attributes(attributes, :birth)
    year_of_death = year_from_attributes(attributes, :death)
    return [] unless year_of_birth and year_of_death
    date_param_string = "YEAR(people.date_of_birth) = ? and 
                         YEAR(people.date_of_death) = ? and 
                         people.estimated_date_of_birth = ? and 
                         people.estimated_date_of_death = ?"
    date_params = [year_of_birth, year_of_death, true, true]
    find_by_name_and_other_criteria(attributes, date_param_string, date_params)
  end
  
  def self.find_by_name_and_other_criteria(attributes, param_string, params, require_firstnames=true)
    firstnames = attributes[:firstnames]
    firstname = attributes[:firstname]
    lastname = attributes[:lastname]
    return [] unless lastname
    if require_firstnames
      return [] unless firstnames and firstname
      name_params = [firstname, lastname] + params
      people_param_string = "people.firstname = ? and 
                             people.lastname = ?"
      names_param_string = "alternative_names.firstname = ? and 
                            alternative_names.lastname = ?"
    else
      name_params = [lastname] + params
      people_param_string = "people.lastname = ?"
      names_param_string = "alternative_names.lastname = ?"
    end
    param_string = " and \n " + param_string if !param_string.blank?
    
    people = find(:all, :conditions => ["#{people_param_string}#{param_string}".squeeze(' ')] + name_params)
    names = AlternativeName.find(:all, :conditions => ["#{names_param_string}#{param_string}".squeeze(' ')] + name_params, 
                                        :include => :person)
    people += names.map{ |name| name.person } if !names.empty?
    if require_firstnames
      name_without_hyphenation = "#{firstnames} #{lastname}".gsub('-', ' ')  
      hyphen_params = [name_without_hyphenation] + params
      people += find(:all, :conditions => ["#{hyphenated_name_criteria('people')} = ?#{param_string}".squeeze(' ')] + hyphen_params)
      names = AlternativeName.find(:all, :conditions => ["#{hyphenated_name_criteria('alternative_names')} = ?#{param_string}".squeeze(' ')] + hyphen_params, :include => :person)
      people += names.map{ |name| name.person } if !names.empty?
    end
    people.uniq
  end
  
  def self.hyphenated_name_criteria(tablename)
    "REPLACE(CONCAT_WS(' ',#{tablename}.full_firstnames, #{tablename}.lastname), '-', ' ')"
  end
  
  def self.find_all_sorted
    people = find(:all, :conditions => ['membership_count > 0'], :order => 'lastname asc')
    people.sort_by(&:ascii_alphabetical_name)
  end
  
  def self.find_partial_matches(partial, limit=5)
    namelist = partial.split(/-| /)
    lastname = namelist.last
    find_options = { :conditions => [ "LOWER(lastname) LIKE ?", '%' + lastname.strip.downcase + '%' ],
                     :order => "lastname ASC" }
    find_options[:limit] = limit if limit
    find(:all, find_options)
  end
  
  def self.find_all_by_names_and_years(attributes, options = {})
    year_of_birth = year_from_attributes(attributes, :birth)
    year_of_death =  year_from_attributes(attributes, :death)
    return [] unless year_of_birth
    if year_of_death
      find(:all, :conditions => ['firstname = ? and lastname = ? and YEAR(date_of_birth) = ? and YEAR(date_of_death) = ?', 
                                 attributes[:firstname], attributes[:lastname], year_of_birth, year_of_death])
    else
      find(:all, :conditions => ['firstname = ? and lastname = ? and YEAR(date_of_birth) = ?', 
                                 attributes[:firstname], attributes[:lastname], year_of_birth])
      
    end
  end
  
  def contributions
    commons_contributions + lords_contributions
  end
  
  def calculate_contribution_count
    commons_contributions.count + lords_contributions.count
  end
  
  def calculate_membership_count
    commons_memberships.count + lords_memberships.count
  end
  
  def name
    if / of$/.match(honorific)
      part_list = [honorific, lastname]
    else
      part_list = [honorific, firstname, lastname]
    end
    part_list.join(' ').strip
  end
  
  def alphabetical_name
    name = lastname
    name += "," if honorific or firstname
    name += " #{firstname}" if firstname
    name += " (#{honorific})" if honorific
    name
  end
  
  def ascii_alphabetical_name
    @ascii_alphabetical_name ||= Person.ascii_form(alphabetical_name)
  end
  
  def name_match? other_firstnames, other_lastname, date
    other_firstnames = other_firstnames.gsub('Rt. Hon. ', '')
    other_firstname = Person.match_form(other_firstnames.split.first)
    other_lastname = Person.match_form(other_lastname)
    return true if Person.match_form(lastname) == other_lastname and Person.match_form(firstname) == other_firstname
    return false
  end
  
  def lastname_match? other_lastname, date
    other = Person.match_form(other_lastname)
    return true if other == Person.match_form(lastname)
    alternative_names.each do |name| 
       date_match = name.start_date <= date and name.end_date >= date 
       name_match = Person.match_form(name.lastname) == other
       return true if date_match and name_match
    end
    return false
  end
  
  def self.ascii_form(name)
    if /&/.match(name)
      name = decode_entities name
    end
    if /[^'A-Za-z0-9\s_-]/.match(name)
      name = Iconv.new('US-ASCII//TRANSLIT', 'UTF-8').iconv(name)
      name.gsub!(/[^'A-Za-z0-9\s_-]+/, '')
    end
    name
  end
  
  def self.match_form(name)
    return "" if name.nil?
    ascii_form(name).downcase
  end
  
  def Person.name_hash name, is_title=false
    name_hash = {}
    name = decode_entities name
    firstname = find_firstname(name)
    name_hash[:firstname] = firstname.downcase if !firstname.blank?
    lastname = find_lastname(name)  
    name_hash[:lastname] = lastname.gsub('-', ' ').downcase if lastname
    name_hash[:lastname] = name_hash[:lastname].gsub(/^m'/, 'mc') if name_hash[:lastname]
    if is_title
      office, name = office_and_name(name)
      name = name.gsub(/^the\s*/i, '')
      name_hash[:title] = name.downcase
      title_place = find_title_place(name_hash[:title])
      name_hash[:title_place] = title_place.downcase if title_place
    end
    if name_hash[:firstname] and name_hash[:lastname]
      name_hash[:fullname] = "#{name_hash[:firstname]} #{name_hash[:lastname]}"  
      name_hash[:initial_and_lastname] = "#{name_hash[:firstname].first} #{name_hash[:lastname]}"
    end
    name_hash
  end
  
  def active_years
    sitting_years = sittings.find(:all, :select => 'distinct year(date) as sitting_year')
    sitting_years.map{ |sitting| sitting.sitting_year.to_i }.sort
  end
  
  def contributions_in_year(year)
    Contribution.find_by_person_in_year(self, year)
  end
  
  def first_sitting
    sittings.find(:first, :order => "date asc")
  end

  def last_sitting
    sittings.find(:first, :order => "date desc")
  end

  def first_contribution
    return nil unless first_sitting
    first_sitting.person_contributions(self).first
  end

  def last_contribution
    return nil unless last_sitting
    last_sitting.person_contributions(self).last
  end
  
end