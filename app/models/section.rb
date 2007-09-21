class Section < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  has_many :contributions, :dependent => :destroy
  has_many :sections, :foreign_key => 'parent_section_id', :dependent => :destroy
  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'

  alias :to_activerecord_xml :to_xml

  MAX_SLUG_LENGTH = 40
  
  acts_as_hansard_element

  def to_slug
    truncate_slug(slugcase_title)
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
  
  def slugcase_title
    slugcase_title = Iconv.new('US-ASCII//TRANSLIT', 'utf-8').iconv(title_cleaned_up)
    slugcase_title.downcase!
    slugcase_title.gsub!(/[^a-z0-9\s_-]+/, '')
    slugcase_title.gsub!(/[\s_-]+/, '-')
    slugcase_title
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
    start_column ? start_column.to_i : nil
  end

  def last_col
    start_column ? start_column.to_i : nil
  end

  def first_image_source
    start_image_src
  end
  
  def title_cleaned_up
    title.gsub('<lb>',' ').gsub('</lb>','').squeeze(' ')
  end
  
  def title_for_linking
    title_cleaned_up.downcase.gsub(/ /, '_')
  end

end
