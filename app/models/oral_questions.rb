class OralQuestions < DebatesSubSection

  belongs_to :section
  has_many :groups, :class_name => "OralQuestionsSection"

end
