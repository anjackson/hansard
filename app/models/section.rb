class Section < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  belongs_to :sitting
  has_many :contributions, :dependent => :destroy
  has_many :sections, :foreign_key => 'parent_section_id', :dependent => :destroy
  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'

  alias :to_activerecord_xml :to_xml
  before_create :create_slug

  MAX_SLUG_LENGTH = 40

  acts_as_hansard_element

  def to_param
    slug
  end

  def id_hash
    {:id    => slug,
     :year  => sitting.date.year,
     :month => month_abbreviation,
     :day   => zero_padded_day,
     :type  => sitting.uri_component}
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

  def create_slug
    self.slug = truncate_slug(slugcase_title)
    index = 1
    candidate_slug = self.slug
    while slug_exists = sitting.sections.find_by_slug(candidate_slug)
      candidate_slug = "#{self.slug}-#{index}"
      index += 1
    end
    self.slug = candidate_slug
  end

  def truncate_slug(string)
    cropped_string = truncate(string, MAX_SLUG_LENGTH+1, "")
    if string != cropped_string
      if cropped_string[0..-1] == "-"
        cropped_string = truncate(cropped_string, MAX_SLUG_LENGTH, "")
      else
        #  back to the last complete word
        last_wordbreak = cropped_string.rindex('-')
        if !last_wordbreak.nil?
          cropped_string = truncate(cropped_string, last_wordbreak, "")
        else
          cropped_string = truncate(cropped_string, MAX_SLUG_LENGTH, "")
        end
      end
    end
    cropped_string
  end

  # strip or convert anything except letters, numbers and dashes
  # to produce a string in the format 'this-is-a-slugcase-string'
  # and convert html entities to unicode
  def slugcase_title
    decoded_title = HTMLEntities.new.decode(title_cleaned_up)
    ascii_title = Iconv.new('US-ASCII//TRANSLIT', 'UTF-8').iconv(decoded_title)
    ascii_title.downcase!
    ascii_title.gsub!(/[^a-z0-9\s_-]+/, '')
    ascii_title.gsub!(/[\s_-]+/, '-')
    ascii_title
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

  def title_cleaned_up
    if title
      clean_title = title.gsub(/<lb>|<\/lb>|<lb\/>/,'')
      clean_title.squeeze!(' ')
      clean_title
    end
  end

  def title_for_linking
    if title
      title_cleaned_up.downcase.gsub(/ /, '_')
    else
      ''
    end
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

  def unnest!
    if can_be_unnested?
      new_parent = parent_section.parent_section
      self.parent_section_id = new_parent.id
      self.save!
    end
  end

  def nest!
    if can_be_nested?
      new_parent = preceding_sibling
      self.parent_section_id = new_parent.id
      self.save!
    end
  end

  protected
    def month_abbreviation
      month = sitting.date.month
      Date::ABBR_MONTHNAMES[month].downcase
    end

    def zero_padded_day
      day = sitting.date.day
      day < 10 ? "0"+ day.to_s : day.to_s
    end

end
