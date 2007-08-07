class OralQuestionSection < Section

  belongs_to :section
  has_many :contributions, :class_name => "OralQuestionContribution"

end
