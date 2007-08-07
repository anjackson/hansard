class OralQuestionsSection < OralQuestions

  belongs_to :section, :class_name => "OralQuestions"
  has_many :questions, :class_name => "OralQuestionSection"

end
