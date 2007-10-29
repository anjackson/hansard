class Section < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  belongs_to :sitting
  has_many :contributions, :dependent => :destroy
  has_many :sections, :foreign_key => 'parent_section_id', :dependent => :destroy
  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'

  alias :to_activerecord_xml :to_xml
  before_create :create_slug
  acts_as_hansard_element
  acts_as_slugged
  
  def self.frequent_titles_in_interval(start_date, end_date, options={})
    options[:limit] ||= 10
    options[:exclude] ||= ['BILL PRESENTED',
                           'Business',
                           'BUSINESS OF THE HOUSE.',
                           'Business of the House',
                           'DELEGATED LEGISLATION',
                           'ORDERS OF THE DAY', 
                           'ORAL ANSWERS TO QUESTIONS', 
                           'ORAL ANSWERS TO<lb></lb> QUESTIONS',
                           'PETITION',
                           'PETITIONS',
                           'Points of Order',
                           'PRAYERS', 
                           'PRIVATE BUSINESS']
                                    
    self.connection.select_values("SELECT   sections.title, count(sections.title) as title_count 
                                   FROM     sections, sittings 
                                   WHERE    sittings.date >= '#{start_date.to_s(:db)}'
                                   AND      sittings.date <= '#{end_date.to_s(:db)}'
                                   AND      sittings.id = sections.sitting_id
                                   AND      sections.title not in ('#{options[:exclude].join('\',\'')}')
                                   GROUP BY sections.title 
                                   ORDER BY title_count desc 
                                   LIMIT #{options[:limit]}")
                                   
  end

  def self.find_by_title_in_interval(title, start_date, end_date)
    find(:all, 
         :include => :sitting, 
         :conditions => ["sections.title = ? 
                          and sittings.date >= ? 
                          and sittings.date <= ? ", title, start_date, end_date], 
         :order => "sittings.date asc")
  end
  
  def year
    date.year
  end

  def date
    sitting.date
  end

  def to_param
    slug
  end

  def id_hash
    sitting.id_hash.merge(:id => slug)
  end

  def find_linkable_section(direction)
    if direction == :previous
      increment = -1
    elsif direction == :next
      increment = 1
    else
      raise ArgumentError, "expecting direction to be :previous or :next"
    end
    all_sections = sitting.sections
    position = all_sections.index(self)
    begin
      position = position + increment
    end while (all_sections.at(position) and !all_sections.at(position).linkable? and position >= 0)
    all_sections.at(position) if position >= 0
  end

  def previous_linkable_section
    find_linkable_section(:previous)
  end

  def next_linkable_section
    find_linkable_section(:next)
  end

  def previous_section
    all_sections = sitting.sections
    all_sections.at(all_sections.index(self) - 1)
  end

  def next_section
    all_sections = sitting.sections
    all_sections.at(all_sections.index(self) + 1)
  end

  def linkable?
    title? or (! parent_section and ! contributions.empty?)
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    marker_xml(options)
    self.outer_tag(options) do
      self.title_xml(options)
      if respond_to? "contributions"
        contributions.each { |contribution| contribution.to_xml(options) }
      end
      sections.each { |section| section.to_xml(options) }
    end
  end

  def title_xml(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    if title
      xml.title do
        xml << title
      end
    end
  end

  def outer_tag(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.section do
      yield
    end
  end

  def first_col
    if start_column
      if start_column.to_i > 0
        return start_column.to_i
      end
    end
    return nil
  end

  def last_col
    start_column ? start_column.to_i : nil
  end

  def first_image_source
    start_image_src
  end

  def plain_title
    if title
      clean_title = title.gsub(/<lb>|<\/lb>|<lb\/>/,'')
      clean_title.squeeze!(' ')
      clean_title
    end
  end

  def following_siblings
    sections = sitting.sections
    index = sections.index(self)
    index = index.next
    siblings = []
    while(index < sections.size and sections[index].parent_section == parent_section)
      siblings << sections[index]
      index = index.next
    end
    siblings
  end

  def preceding_sibling
    if parent_section
      index = parent_section.sections.index(self)
      if index > 0
        parent_section.sections[index - 1]
      else
        nil
      end
    else
      index = sitting.sections.index(self)
      if index > 0
        sitting.sections[index - 1]
      else
        nil
      end
    end
  end

  def can_be_nested?
    preceding_sibling ? true : false
  end

  def can_be_unnested?
    if parent_section
      parent_section.is_a?(Debates) ? false : true
    else
      false
    end
  end

  def unnest! traverse_following_siblings=true
    if can_be_unnested?
      new_parent = parent_section.parent_section
      if traverse_following_siblings
        self.following_siblings.each do |sibling|
          sibling.unnest!(false)
        end
      end
      self.parent_section = new_parent
      self.save!
    end
  end

  def nest!
    if can_be_nested?
      new_parent = preceding_sibling
      self.parent_section = new_parent
      self.save!
    end
  end

  def create_slug
    self.slug = make_slug(plain_title) do |candidate_slug|
      duplicate_found = sitting.sections.find_by_slug(candidate_slug)
      duplicate_found
    end
  end

end
