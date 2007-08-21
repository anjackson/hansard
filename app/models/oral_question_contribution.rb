class OralQuestionContribution < MemberContribution

  belongs_to :section, :class_name => "OralQuestionSection", :foreign_key => 'section_id'

end
