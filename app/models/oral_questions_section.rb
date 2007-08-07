class OralQuestionsSection < OralQuestions

  belongs_to :parent_section, :class_name => "OralQuestions", :foreign_key => 'parent_section_id'
  has_many :questions, :class_name => "OralQuestionSection", :foreign_key => 'parent_section_id'

end
