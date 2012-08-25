class Section < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::SanitizeHelper
  belongs_to :sitting
  has_many :contributions, :dependent => :destroy
  has_many :division_placeholders, :class_name => "DivisionPlaceholder", :foreign_key => 'section_id', :include => :division
  has_many :sections, :foreign_key => 'parent_section_id', :dependent => :destroy
  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'
  has_many :act_mentions, :dependent => :destroy
  has_many :bill_mentions, :dependent => :destroy

  alias :to_activerecord_xml :to_xml
  alias :to_original_json :to_json
  before_create :create_slug
  before_validation_on_create :clean_title
  before_validation_on_create :populate_mentions
  acts_as_hansard_element
  acts_as_slugged

  def is_bill_debate?
    title.blank? ? false : (BillResolver.new(title).references.size > 0 ? true : false)
  end

  def is_clause?
    title.blank? ? false : (title[/^(new)?\s?clause/i] ? true : false)
  end

  def is_orders_of_the_day?
    title.blank? ? false : (title[/^orders of the day\.?$/i] ? true : false)
  end

  def is_business_of_the_house?
    title.blank? ? false : (title[/^business of the house(,|\.)?$/i] ? true : false)
  end

  def mentions
    all_mentions = bill_mentions + act_mentions
    all_mentions.select{|mention| !mention.contribution_id }.sort_by(&:start_position)
  end

  def division_count
    division_placeholders.size
  end

  def divisions
    division_placeholders = contributions.select{ |c| c.is_a? DivisionPlaceholder }
    division_placeholders.collect(&:division).compact.sort_by(&:id)
  end

  def index_of_division division
    divisions.index division
  end

  def word_count
    length = contributions.inject(0) do |count, contribution|
      count + (contribution.text ? contribution.text.split(/\S+/).size : 0)
    end

    if (unlinkable_children = sections.select{ |section| !section.linkable? })
      unlinkable_children.each { |child| length += child.word_count }
    end
    length
  end

  alias :words :word_count

  def link_id
    'section_' + id.to_s
  end

  def to_json(options = { :include => {:sections => {}, :contributions => {}}})
    to_original_json(options)
  end
  
  def column_reference
    sitting.column_reference(start_column, end_column)
  end

  def hansard_reference
    sitting.hansard_reference(start_column, end_column)
  end

  def sitting_title
    sitting.title
  end

  def sitting_uri_component
    sitting.uri_component
  end

  def sitting_class
    sitting.class
  end

  def sitting_type
    sitting.sitting_type_name
  end

  def year
    date.year
  end

  def month
    date.month
  end

  def id_hash
    sitting.id_hash.merge(:id => slug)
  end

  def first_member
    if !contributions.empty?
      return contributions.first.member_name
    elsif !sections.empty?
      return sections.first.first_member
    end
  end

  def find_division division_number
    number = division_number.to_s.sub('division_', '').to_i
    divisions.find { |d| d.number == number }
  end

  def find_linkable_section(direction)
    increment = increment_number(direction)
    all_sections = sitting.all_sections
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
    all_sections = sitting.all_sections
    all_sections.at(all_sections.index(self) - 1)
  end

  def next_section
    all_sections = sitting.all_sections
    all_sections.at(all_sections.index(self) + 1)
  end

  def linkable?
    !title.blank?
  end

  def parent_sections(parentlist=[])
    return parentlist if !parent_section
    parentlist << parent_section
    parent_section.parent_sections(parentlist)
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
        xml << title.to_xs
      end
    end
  end

  def outer_tag(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.section do
      yield
    end
  end

  def following_siblings
    sections = sitting.all_sections
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
    sections = parent_section ? parent_section.sections : sitting.direct_descendents
    has_preceding = (index = sections.index(self)) > 0
    has_preceding ? sections[index - 1] : nil
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

  def clean_title
    if title
      Bill.correct_HL_variants title
      title.gsub!(/<lb>|<\/lb>|<lb\/>/,' ')
      title.gsub!(/^\("/,'')
      title.gsub!(' OP ', ' OF ')
      title.gsub!("\n",' ')
      title.gsub!("\r",' ')
      title.gsub!(/^(\d+\.)([A-Z])/, '\1 \2')
      title.gsub!(/^"/,'') unless title.index('"',1)
      title.gsub!(/\A\[?([^\[]+)\](\.?)(&#x2014;)?$/,'\1\2\3')
      title.squeeze!(' ')
      title.chomp!(' ')
      title.sub!('PROVI SIONAL', 'PROVISIONAL')
    end
  end

  def create_slug
    self.slug = make_slug(title) do |candidate_slug|
      duplicate_found = sitting.all_sections.find_by_slug(candidate_slug)
      duplicate_found
    end
  end

  def slug_start_index(slug)
    return 1 unless slug.blank?
    highest_blank_slug = sitting.all_sections.find(:first, :conditions => ["title is null"], :order => "id desc")
    if highest_blank_slug
      highest_blank_slug.slug[1..highest_blank_slug.slug.size].to_i + 1
    else
      1
    end
  end

  def populate_mentions
    mentionables = [[Act, act_mentions], [Bill, bill_mentions]]
    if title
      mentionables.each do |mentionable_class, mention_association|
        mentionable_class.populate_mentions(title, self, nil).each do |mention|
          mention_association << mention
        end if mention_association.empty?
      end
    end
  end

  def title_via_associations
    return title if !title.blank?
    parent_sections.each do |parent|
      return parent.title if !parent.title.blank?
    end
    return sitting.title
  end

  def body
    if sections.size == 1 && sections.first.is_a?(WrittenAnswersBody)
      sections.first
    elsif sitting.is_a?(WrittenAnswersSitting)
      self
    else
      nil
    end
  end

  def in_columns? column_text, end_column_text
    the_column =  Sitting.column_number(column_text)
    the_end_column =  Sitting.column_number(end_column_text)
    from_column = Sitting.column_number(start_column)
    to_column =   Sitting.column_number(end_column)

    in_column = (the_column >= from_column && the_end_column <= to_column)
    in_column
  end

  def in_column? column_text
    the_column =  Sitting.column_number(column_text)
    from_column = Sitting.column_number(start_column)
    to_column =   Sitting.column_number(end_column)

    in_column = (the_column >= from_column && the_column <= to_column)
    in_column
  end

  def add_contribution contribution
    contribution.section = self
    self.contributions << contribution
  end

  def preceding_contribution contribution
    index = contributions.index contribution
    if index == 0
      nil
    else
      contributions[index - 1]
    end
  end

  def following_contribution contribution
    index = contributions.index contribution
    if index == (contributions.size - 1)
      nil
    else
      contributions[index + 1]
    end
  end

  def add_section child
    if is_orders_of_the_day? && child.is_clause? && sections.last && sections.last.is_bill_debate?
      clause = child
      bill_debate = sections.last
      clause.parent_section = bill_debate
      bill_debate.sections << clause
    else
      child.parent_section = self
      self.sections << child
    end
  end

  def members_in_section
    @members_in_section ||= []
  end
  
  def is_written_body?
    false
  end

  private

    def increment_number direction
      if direction == :previous
        -1
      elsif direction == :next
        1
      else
        raise ArgumentError, "expecting direction to be :previous or :next"
      end
    end

end
