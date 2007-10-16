class OralQuestionsSection < Section

  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'
  has_many :questions, :class_name => "OralQuestionSection", :foreign_key => 'parent_section_id', :dependent => :destroy
  has_one :introduction, :class_name => 'ProceduralContribution', :foreign_key => 'section_id'

end
