class LordsMembership < ActiveRecord::Base
  belongs_to :person
  has_many :lords_contributions, :class_name => "Contribution"
  acts_as_id_finder
  acts_as_membership
  acts_as_string_normalizer
  
  def self.query_date_params
    '(lords_memberships.start_date <= ? or lords_memberships.start_date is null) and 
      (lords_memberships.end_date >= ? or lords_memberships.end_date is null)'
  end
  
  def self.create_year_degree_and_title_params(attributes, param_string)
    date_params = [attributes[:start_date].year]
    if attributes[:end_date]
      param_string += ' and (year(end_date) = ? or end_date is null)'
      date_params << attributes[:end_date].year
    end
    [param_string, date_params]
  end
  
  def self.find_by_years_degree_and_title(attributes)
    param_string = '((title = ? and degree = ?) or name = ?) and year(start_date) = ?'
    param_string, date_params = create_year_degree_and_title_params(attributes, param_string)
    membership = nil
    alternative_degrees = LordsMembership.alternative_degrees(attributes[:degree])
    alternative_titles = LordsMembership.alternative_titles(attributes[:degree], attributes[:title])
    alternative_degrees.each do |alternative_degree|
      alternative_titles.each do |alternative_title|
        membership = find(:first, :conditions => [param_string, 
                                                  alternative_title,
                                                  alternative_degree, 
                                                  "#{alternative_degree} #{alternative_title}"] + date_params) if ! membership
      end
    end  
    
    if ! membership and ! LordsMembership.find_title_place("attributes[:degree] #{attributes[:title]}")
      param_string = '((title like ? and degree = ?) or name like ?) and year(start_date) = ?'
      param_string, date_params = create_year_degree_and_title_params(attributes, param_string)
      alternative_degrees.each do |alternative_degree|
        alternative_titles.each do |alternative_title|
          membership = find(:first, :conditions => [param_string, 
                                                    "#{alternative_title} of %",
                                                    alternative_degree, 
                                                    "#{alternative_degree} #{alternative_title} of %"] + date_params) if ! membership
        end
      end
    end
                   
    membership
  end

  def self.count_on_date(date)
    memberships = find(:all, :conditions => [query_date_params, date, date])
    memberships.map{ |membership| membership.person_id }.uniq.size
  end  
  
  def self.members_on_date(date)
    find(:all, :conditions => [query_date_params, date, date], :include => {:person => [:alternative_names, :alternative_titles]})
  end
  
  def self.find_duplicates(year)
    duplicates = []
    members_by_title = members_on_date(Date.new(year, 12,31)).sort_by(&:title)
    prev = nil
    members_by_title.each do |member|
      if prev and member.title == prev.title and normalize_degree(member.degree) == normalize_degree(prev.degree) and prev.person != member.person
        duplicates << [member.person.slug, prev.person.slug]
      end
      prev = member
    end
    duplicates
  end
  
  def self.normalize_degree(degree)
    baron_version = degree.strip.gsub(/^Lord$/, 'Baron')
  end
  
  def self.members_on_date_by_person(date)
    members = members_on_date(date)
    if !members.empty?
      members = members.group_by(&:person_id).sort do |a,b|
        a[1][0].person.lastname <=> b[1][0].person.lastname
      end
      [members.size, members]
    else
      [0, []]
    end
  end
  
  def self.json_defaults
    { :except => id_attributes }
  end
  
  def self.get_memberships_by_name(name, membership_lookups)
    name_hash = Person.name_hash(name, is_title=true)
    memberships = []
    if name_hash[:title]
      title_versions(name_hash[:title]).each do |version|
        if name_hash[:title_place]
          memberships += membership_lookups[:place_titles][version]
        else
          memberships += membership_lookups[:titles][version]
        end
      end
      if memberships.empty?
        title_versions(name_hash[:title]).each do |version|
          if name_hash[:title_place]
            memberships += membership_lookups[:titles][title_without_place(version)] if memberships.empty?
          end
        end
      end
    end
    memberships.uniq
  end
  
  def self.title_versions(title)
    versions = []
    degree = LordsMembership.find_title_degree(title)
    return [title] unless degree
    title = LordsMembership.title_without_degree(title)
    LordsMembership.alternative_degrees(degree).each do |alternative|
      versions << "#{alternative} #{title}".downcase
    end
    versions
  end
  
  def self.lookup_hash_keys
    [:lastnames, :office_names, :place_titles, :titles]
  end
    
  def degree_and_title
   "#{degree} #{title}"
  end
  
  def start_year
    start_date ? start_date.year : nil
  end
  
  def end_year 
    end_date ? end_date.year : nil
  end
  
end