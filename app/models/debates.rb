class Debates < Section

  belongs_to :sitting
  has_many :sections

  def oral_questions
    sections.select {|s| s.is_a? OralQuestions}[0]
  end

end
