class OralQuestionContribution < MemberContribution

  belongs_to :parent_section, :class_name => "OralQuestionSection", :foreign_key => 'parent_section_id'

end
