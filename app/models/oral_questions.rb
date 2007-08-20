class OralQuestions < Section

  has_many :sections, :class_name => "OralQuestionsSection", :foreign_key => 'parent_section_id'

  def outer_tag xml
    xml.oralquestions do
      yield
    end
  end
  
end
