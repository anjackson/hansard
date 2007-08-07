class OralQuestionContribution < MemberContribution

  belongs_to :section, :class_name => "OralQuestionSection", :foreign_key => 'section_id'

  def member_contribution
    text
  end
end
