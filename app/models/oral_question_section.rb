class OralQuestionSection < Section

  belongs_to :parent_section, :class_name => "OralQuestionsSection", :foreign_key => 'parent_section_id'
  has_many :contributions, :class_name => "OralQuestionContribution", :foreign_key => 'section_id', :order => "xml_id"

  alias :to_activerecord_xml :to_xml
  
  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.section do
      xml.title(title) 
        elements_xml(:builder => xml, :elements => contributions)
    end
  end

end
