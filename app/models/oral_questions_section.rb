class OralQuestionsSection < DebatesSubSection

  belongs_to :section
  has_many :questions, :class_name => "OralQuestionSection"

end
