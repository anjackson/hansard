class Section < ActiveRecord::Base

  has_many :contributions, :dependent => :destroy
  has_many :sections, :foreign_key => 'parent_section_id', :dependent => :destroy
  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'

  alias :to_activerecord_xml :to_xml

  acts_as_hansard_element

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
    xml.title do
      xml << title if title
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

end
