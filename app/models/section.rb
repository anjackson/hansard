class Section < ActiveRecord::Base

  has_many :contributions
  has_many :sections, :foreign_key => 'parent_section_id'
  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'
  alias :to_activerecord_xml :to_xml

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    self.outer_tag(options) do
      self.title_xml(options)
      elements_xml(:builder => xml, :elements => contributions) if self.respond_to? "contributions"
      elements_xml(:builder => xml, :elements => sections)
    end
  end
  
  def elements_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    elements = options.delete(:elements)
    last_element = nil
    elements.each do |element|
      if element.kind_of? Section
        if !element.start_image_src.nil? 
          xml.image(:src => element.start_image_src)
        end
        if !element.start_column.nil?
          xml.col(element.start_column)
        end
      else
        if last_element
          if element.different_image(last_element)
            if not(/<image src="#{element.image_sources.first}"/.match(element.text) or /<image src="#{element.image_sources.first}"/.match(last_element.text))
              xml.image(:src => element.first_image_source)
            end
          end
          if element.cols && last_element.cols && element.cols.first && element.cols.first != last_element.cols.last
            if not(/<col>#{element.cols.first}/.match(element.text) or /<col>#{element.cols.first}/.match(last_element.text))
              xml.col(element.cols.first)
            end
          end
        end
      end
      element.to_xml(options)
      last_element = element
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
   
end
