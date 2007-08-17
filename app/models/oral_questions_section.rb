class OralQuestionsSection < Section

  belongs_to :parent_section, :class_name => "OralQuestions", :foreign_key => 'parent_section_id'
  has_many :questions, :class_name => "OralQuestionSection", :foreign_key => 'parent_section_id'
  has_one :introduction, :class_name => 'ProceduralContribution', :foreign_key => 'section_id'
  
  alias :to_activerecord_xml :to_xml
  
  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    questions.each do |question|
      question.to_xml(options)
    end
  end
  
end
