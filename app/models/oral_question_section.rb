class OralQuestionSection < Section

  belongs_to :parent_section, :class_name => "OralQuestionsSection", :foreign_key => 'parent_section_id'
end
