class CommonsMembership < ActiveRecord::Base
  belongs_to :constituency
  belongs_to :person
  has_many :commons_contributions, :class_name => "Contribution"
  acts_as_id_finder
  acts_as_membership
  acts_as_life_period
  
  def self.json_defaults
    { :except => id_attributes,
      :include => { :person => { :except => Person.id_attributes }, 
                    :constituency => { :except => Constituency.id_attributes } } } 
  end

  def person_name
    person.name
  end
  
  def constituency_name
    constituency.complete_name
  end
  
  def matches_attributes?(attributes, match_criteria)
    match = true
    if match_criteria.include? :constituency
      match = false unless constituency.match?(attributes[:constituency]) 
    end  
    if match_criteria.include? :lastname
       match = false unless person.lastname_match?(attributes[:lastname], start_date)
    end
    if match_criteria.include? :name
      match = false unless person.name_match?(attributes[:firstnames], attributes[:lastname], start_date)
    end
    return match
  end
  
  def self.match_memberships attributes, memberships, criteria
    matches = memberships.select do |membership| 
      membership.matches_attributes?(attributes, criteria) 
    end
    if matches.size == 1 
      return matches.first
    end
    return nil
  end
  
  def self.find_matches(attribute_list, member_list, criteria)
    matches = []
    attribute_list.each do |member_attributes|   
      match = match_memberships(member_attributes, member_list, criteria)
      if match
        matches << [match, member_attributes]
        member_list.delete(match)
      end
    end
    matches
  end
  
  def self.delete_matches(matches, member_list, attribute_list)
    matches.each do |member, attributes|
      attribute_list.delete(attributes) 
    end
  end
  
  def self.find_matches_on_date(date, member_attributes)
    member_list = members_on_date(date)
    
    complete_matches = find_matches(member_attributes, member_list, [:constituency, :lastname])
    delete_matches(complete_matches, member_list, member_attributes)
    
    constituency_matches = find_matches(member_attributes, member_list, [:constituency])
    delete_matches(constituency_matches, member_list, member_attributes)

    name_matches = find_matches(member_attributes, member_list, [:name])
    delete_matches(name_matches, member_list, member_attributes)
        
    lastname_matches = find_matches(member_attributes, member_list, [:lastname])
    delete_matches(lastname_matches, member_list, member_attributes)

    
    { :complete_matches => complete_matches, 
      :lastname_matches => lastname_matches,
      :name_matches => name_matches, 
      :constituency_matches => constituency_matches,
      :unmatched_members => member_list,
      :unmatched_attributes => member_attributes }
  end
  
  def self.query_date_params
    '(commons_memberships.start_date <= ? or commons_memberships.start_date is null) and 
      (commons_memberships.end_date >= ? or commons_memberships.end_date is null)'
  end

  def self.count_on_date(date)
    count(:conditions => [query_date_params, date, date])
  end
  
  def self.members_on_date(date)
    find(:all, :conditions => [query_date_params, date, date], :include => [{:person => [:alternative_names, {:office_holders => :office}]}])
  end
  
  def self.members_on_date_by_constituency(date)
    members = find(:all, :conditions => [query_date_params, date, date], :include => [:person, :constituency])
    if !members.empty?
      members = members.group_by(&:constituency_id).sort do |a,b|
        a[1][0].constituency_name <=> b[1][0].constituency_name
      end
      [members.size, members]
    else
      [0, []]
    end
  end
  
  def self.find_duplicates(year)
    duplicates = []
    constituencies = members_on_date(Date.new(year, 12,31)).map{|m| m.constituency }.sort_by(&:id)
    prev = nil
    constituencies.each do |constituency|
      if prev and constituency.id == prev.id
        duplicates << constituency
      end
      prev = constituency
    end
    duplicates
  end
  
  def self.get_memberships_by_name(name, membership_lookups)
    fullnames = membership_lookups[:fullnames]
    initial_and_lastnames = membership_lookups[:initial_and_lastnames]
    lastnames = membership_lookups[:lastnames]
    name_hash = Person.name_hash(name)
    memberships = []
    return memberships unless name_hash[:lastname]

    if name_hash[:firstname]
      memberships = fullnames[name_hash[:fullname]]
      memberships += lastnames[name_hash[:fullname]] 
      memberships = initial_and_lastnames[name_hash[:initial_and_lastname]] if memberships.empty?
    end
    memberships = lastnames[name_hash[:lastname]] if memberships.empty?
    memberships.uniq
  end
  
  def self.lookup_hash_keys
    [:fullnames, :lastnames, :initial_and_lastnames, :constituency_ids, :office_names]
  end
  
  def match_by_year(attributes)
    return false unless attributes[:start_date]
    return false unless start_date
    return false unless start_date.year == attributes[:start_date].year
    if attributes[:end_date] 
      return false unless end_date
      return false unless end_date.year == attributes[:end_date].year
    end
    true
  end
  
  def lastname_match?(attributes)
     return true if person.lastname == attributes[:lastname]
     alternative_name_match = person.alternative_names.detect do |name| 
       if date_overlap?(name.first_possible_date, name.last_possible_date)
         if attributes[:lastname] == name.lastname
           true
         else
           false
         end
       else
         false
       end
     end
     return true if alternative_name_match
     return false
  end
  
  def date_overlap?(other_start_date, other_end_date)
    return false unless start_date
    return false unless other_start_date
    if other_end_date and end_date
      return true if other_end_date >= start_date and other_start_date <= end_date
    elsif other_end_date
      return true if other_end_date >= start_date
    elsif end_date
      return true if end_date >= other_start_date
    else
      return true
    end
    return false
  end
  
  def match_by_overlap_and_name(attributes)
    full_name_matches = Person.find_by_name_and_other_criteria(attributes, '', [])
    return false unless (full_name_matches.include?(person) or lastname_match?(attributes))
    date_overlap?(attributes[:start_date], attributes[:end_date])
  end
  
end