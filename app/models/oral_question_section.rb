class OralQuestionSection < Section

  belongs_to :parent_section, :class_name => "OralQuestionsSection", :foreign_key => 'parent_section_id'
  has_many :contributions, :class_name => "OralQuestionContribution"

end
