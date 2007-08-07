class OralQuestions < DebatesSection

  belongs_to :parent_section, :class_name => "Debates", :foreign_key => 'parent_section_id'
  has_many :sections, :class_name => "OralQuestionsSection", :foreign_key => 'parent_section_id'

end
