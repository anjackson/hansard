class OralQuestionSection < Section

  belongs_to :parent_section, :class_name => "OralQuestionsSection", :foreign_key => 'parent_section_id'
  has_many :contributions, :class_name => "OralQuestionContribution", :foreign_key => 'section_id', :order => "xml_id"

  alias :to_activerecord_xml :to_xml
  

end
