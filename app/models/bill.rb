class Bill < ActiveRecord::Base

  validates_uniqueness_of :slug
  before_validation_on_create :populate_slug
  has_many :mentions, :class_name => 'BillMention', :order => "sitting_id asc, section_id asc, contribution_id asc", :dependent => :destroy 
  has_many :sections, :through => :mentions
  acts_as_slugged :field => :name_and_number
  acts_as_mentionable :resolver_class_name => 'BillResolver', :mention_class_name => 'BillMention'
  acts_as_duplicate_retryer

  def Bill.find_all_sorted
    find(:all, :order => "name asc, number asc")
  end

  def Bill.find_or_create_from_resolved_attributes(attributes)
    find_or_create_from_name_and_number(attributes[:name], attributes[:number])
  end

  BILL_VARIANTS = regexp '(BILL)\.', 'i' unless defined? BILL_VARIANTS
  DOT_VARIANTS = '(\.|,| |)+' unless defined? DOT_VARIANTS
  HL_VARIANTS = regexp '(\[|\()'+DOT_VARIANTS+'(H|[^H])'+DOT_VARIANTS+'LL?'+DOT_VARIANTS+ '(\]|\)|1|$)\.?' unless defined? HL_VARIANTS
  HL_NEEDS_SPACE = regexp '([^ ])\[' unless defined? HL_NEEDS_SPACE

  def Bill.correct_HL_variants text
    HL_VARIANTS.gsub!(text, '[H.L.]') if text
    HL_NEEDS_SPACE.gsub!(text, '\1 [') if text
    text
  end

  def Bill.normalize_name text
    correct_HL_variants text
    BILL_VARIANTS.sub!(text, '\1')
    text
  end

  def Bill.find_or_create_from_name_and_number(name, number)
    name = normalize_name(name)
    bill = find_by_name_and_number(name, number)
    if bill and bill.name == bill.name.upcase and name != name.upcase
      bill.name = name
      bill.save
    end
    bill = create(:name => name, :number => number) unless bill
    bill
  end

  def Bill.find_by_name_and_number(name, number)
    name = normalize_name(name)
    if number
      find(:first, :conditions => ["LOWER(name) = ? and number = ?", name.downcase, number])
    else
      bills = find(:all, :conditions => ["LOWER(name) = ?", name.downcase]).delete_if{|b| b.number}
      bills.empty? ? nil : bills.first
    end
  end

  def Bill.find_partial_matches(partial, limit=5)
    find_options = {  :conditions => [ "LOWER(name) LIKE ?", '%' + partial.downcase + '%' ],
                      :order => "name ASC",
                      :limit => limit }
    find(:all, find_options)
  end

  def Bill.find_from_text text
    text = normalize_name(text)
    name, number = BillResolver.determine_name_and_number(text)
    bill = name ? find_by_name_and_number(name, number) : nil
    bill
  end

  def first_mentions
    mentions.find(:all, 
                  :include => {:section => :sitting, :contribution => {}}, 
                  :conditions => ['first_in_section = ?', true],
                  :order => 'date asc')
  end
  
  def name_and_number
    number ? "#{name} No. #{number}" : name
  end

  def id_hash
    { :name => slug }
  end

  def others_by_name
    Bill.find_all_by_name(name, :conditions => ['id != ?', id])
  end
end