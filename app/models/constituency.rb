class Constituency < ActiveRecord::Base
  before_validation_on_create :populate_slug
  validates_uniqueness_of :slug
  validates_uniqueness_of :name, :scope => [:start_year, :area_type, :region]
  has_many :contributions
  has_many :commons_memberships
  has_many :constituency_aliases
  acts_as_slugged :field => :complete_name
  acts_as_string_normalizer
  acts_as_id_finder

  def self.find_partial_matches(partial, limit=5)
    find_options = {  :conditions => [ "LOWER(name) LIKE ?", '%' + partial.downcase + '%' ],
                      :order => "name ASC",
                      :limit => limit }
    find(:all, find_options)
  end

  def Constituency.find_by_name name
    find(:first, :conditions => ["LOWER(name) = ?", name.downcase])
  end

  def self.find_all_sorted
    Constituency.find(:all).sort_by(&:name)
  end

  def self.find_constituency slug
    Constituency.find_by_slug(slug)
  end
  
  def self.find_by_name_and_years(attributes)
    return [] if !attributes[:name]
    return [] if !attributes[:start_date] and !attributes[:end_date]
    start_year = attributes[:start_date].year if attributes[:start_date]
    end_year = attributes[:end_date].year if attributes[:end_date]    
    name = attributes[:name]
    if start_year and end_year
      find(:all, :conditions => ['name = ? and start_year >= ? and start_year <= ?
                                           and end_year >= ? and end_year <= ?'.squeeze(' '), 
                 name, start_year - 1, start_year + 1, end_year - 1, end_year + 1])
    elsif attributes[:start_date]
      find(:all, :conditions => ['name = ? and start_year >= ? and start_year <= ?', 
                 name, start_year - 1, start_year + 1])
    else 
      find(:all, :conditions => ['name = ? and end_year >= ? and end_year <= ?', 
                 name, end_year - 1, end_year + 1])
    end 
  
  end

  def self.find_by_name_and_date(name, date)
    year = date.year
    versions = generate_versions(name)
    result = []
    versions.each do |version|
      result = find(:all, :conditions => name_and_date_conditions(version, year)) if result.empty?
      result = find_by_alias(version, date) if result.empty?
    end
    return result.first if result.size == 1
    return nil
  end
  
  def Constituency.match_form name
     name.gsub(/[^\w\s]/, ' ').downcase.split.sort.join(' ')
  end

  def missing_dates
    missing_dates = []
    current_date = Date.new(start_year, 1, 1)
    memberships = commons_memberships.map { |membership| [membership.first_possible_date, membership.last_possible_date]}
    memberships.sort.each do |membership_first_date, membership_last_date|
      unless membership_first_date.year <= current_date.year
        if (membership_first_date - 1.year) > current_date
          missing_dates << [current_date, membership_first_date]
        end
      end
      current_date = membership_last_date
    end
    end_date = Date.new(end_year || LAST_DATE.year, 1, 1)
    missing_dates << [current_date, end_date] if (end_date - 1.year ) > current_date
    missing_dates
  end

  def self.find_by_alias(name, date)
    conditions = ['alias = ? and start_date <= ? and end_date >= ?', name, date, date]
    constituency_aliases = ConstituencyAlias.find(:all, :conditions => conditions, :include => :constituency)
    constituency_aliases.map{ |cons_alias| cons_alias.constituency }
  end

  def self.name_and_date_conditions(name, year)
    ["name = ? and start_year <= ? and (end_year >= ? or end_year is null)", name, year, year]
  end

  def complete_name
    complete_name = name
    complete_name += " (#{area_type})" if area_type
    complete_name += " (#{region})" if region
    complete_name
  end

  def years
    years = ''
    years = "#{start_year}-#{end_year}" if start_year
    years
  end

  def id_hash
    { :name => slug }
  end
  
  def match? other_name
    other = Constituency.match_form(other_name)
    return true if Constituency.match_form(name) == other
    return true if constituency_aliases.any?{|constituency_alias| Constituency.match_form(constituency_alias.alias) == other }
    return false
  end
  
  def history_doc
    RAILS_ROOT + '/public/constituency-histories/' + self.slug + '.doc'
  end

  protected

    def Constituency.generate_versions name
      corrected_name = corrected_name(name)
      return [] if !corrected_name
      normalized_name = normalized_name(corrected_name)
      stripped_name = stripped_name(normalized_name)
      name_without_apostrophes = name_without_apostrophes(stripped_name)
      [corrected_name, normalized_name, stripped_name, name_without_apostrophes]
    end

    def Constituency.corrected_name name
      return nil if detect_non_constituency_words(name)
      return nil if detect_honorifics(name)
      name = String.new name
      name = name.gsub('.', '')
      name = correct_hyphen_variants(name)
      name = correct_spaced_hyphens(name)
      name = correct_tags(name)
      name = correct_trailing_punctuation(name)
      name = correct_common_word_variants(name)
      name.strip
    end

    def Constituency.normalized_name name
      name = String.new name
      name = move_the_to_end(name)
      name = correct_compass_variants(name)
    end

    def Constituency.stripped_name name
      name = String.new name
      name = name.gsub(',', '')
      name = name.gsub('-', ' ')
      name = name.gsub('City of ', '')
    end

    def Constituency.name_without_apostrophes name
      name = name.gsub("'", '')
    end

end