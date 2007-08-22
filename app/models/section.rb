class Section < ActiveRecord::Base

  has_many :contributions
  has_many :sections, :foreign_key => 'parent_section_id'
  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'
  alias :to_activerecord_xml :to_xml

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml_markers(options)
    self.outer_tag(options) do
      self.title_xml(options)
      if respond_to? "contributions"
        contributions.each { |contribution| contribution.to_xml(options) }
      end
      sections.each { |section| section.to_xml(options) }
    end
  end
  
  def xml_markers(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    if start_image_src && start_image_src != options[:current_image_src]
      xml.image(:src => start_image_src)
      options[:current_image_src] = start_image_src
    end
    if first_col && first_col > options[:current_column]
      xml.col(first_col)
      options[:current_column] = first_col
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
end
