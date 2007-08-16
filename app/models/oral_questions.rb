class OralQuestions < Section

  has_many :sections, :class_name => "OralQuestionsSection", :foreign_key => 'parent_section_id'

end
