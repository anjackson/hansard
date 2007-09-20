require 'cgi'
class Section < ActiveRecord::Base

  include ActionView::Helpers::TextHelper
  has_many :contributions, :dependent => :destroy
  has_many :sections, :foreign_key => 'parent_section_id', :dependent => :destroy
  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'

  alias :to_activerecord_xml :to_xml

  MAX_SLUG_LENGTH = 40
  
  acts_as_hansard_element

  def to_slug
    normalized_title = Iconv.new('US-ASCII//TRANSLIT', 'utf-8').iconv(title)
    normalized_title.downcase!
    normalized_title.gsub!(/[^a-z0-9\s_-]+/, '')
    normalized_title.gsub!(/[\s_-]+/, '-')
    normalized_title = CGI::escape(normalized_title)
    cropped_title = truncate(normalized_title, MAX_SLUG_LENGTH+1, "")
    if normalized_title != cropped_title
      if cropped_title[0..-1] == "-"
        cropped_title = truncate(cropped_title, MAX_SLUG_LENGTH, "")
      else
        #  back to the last complete word
        last_wordbreak = cropped_title.rindex('-')
        if !last_wordbreak.nil? 
          cropped_title = truncate(cropped_title, last_wordbreak, "")
        else
          cropped_title = truncate(cropped_title, MAX_SLUG_LENGTH, "")
        end
      end
    end
    cropped_title
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
