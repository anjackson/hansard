class Act < ActiveRecord::Base

  validates_uniqueness_of :slug
  before_validation_on_create :populate_slug
  has_many :mentions, :class_name => 'ActMention', :order => "sitting_id asc, section_id asc, contribution_id asc", :dependent => :destroy
  has_many :sections, :through => :mentions
  acts_as_slugged :field => :name_and_year
  acts_as_mentionable :resolver_class_name => 'ActResolver', :mention_class_name => 'ActMention'
  acts_as_duplicate_retryer

  def name_and_year
    name_and_year_string = name
    name_and_year_string = "#{name_and_year_string} #{year}" if year
    name_and_year_string
  end

  def self.find_all_sorted
    find(:all, :order => "name asc, year asc")
  end

  def self.find_or_create_from_resolved_attributes(attributes)
    act = find_by_name_and_year(attributes[:name], attributes[:year])
    if act and act.name == act.name.upcase and attributes[:name] != attributes[:name].upcase
      act.name = attributes[:name]
      act.save
    end
    act = create(:name => attributes[:name], :year => attributes[:year]) unless act
    act
  end

  def self.find_by_name_and_year(name, year)
    return find(:first, :conditions => ["LOWER(name) = ? and year = ?", name.downcase, year]) if year
    find(:first, :conditions => ["LOWER(name) = ?", name.downcase])
  end

  def self.find_partial_matches(partial, limit=5)
    find_options = {  :conditions => [ "LOWER(name) LIKE ?", '%' + partial.downcase + '%' ],
                      :order => "name ASC",
                      :limit => limit }
    find(:all, find_options)
  end

  def id_hash
    { :name => slug }
  end
  
  def first_mentions
    mentions.find(:all, 
                  :include => {:section => :sitting, :contribution => {}}, 
                  :conditions => ['first_in_section = ?', true],
                  :order => 'date asc')
  end
  
  def others_by_name
    Act.find_all_by_name(name, :conditions => ['id != ?', id])
  end
  
end