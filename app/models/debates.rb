class Debates < Section

  belongs_to :sitting
  has_many :sections, :class_name => "Section", :foreign_key => 'parent_section_id'

  def oral_questions
    sections.select {|s| s.is_a? OralQuestions}[0]
  end

end
