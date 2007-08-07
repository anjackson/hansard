class DebatesSection < Section

  belongs_to :sitting
  has_many :sections

  def oral_questions
    sections.select {|s| s.is_a? OralQuestionsSection}[0]
  end

end
