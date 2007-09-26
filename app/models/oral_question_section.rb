class OralQuestionSection < Section

  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'
  has_many :questions, :class_name => "OralQuestionSection", :foreign_key => 'parent_section_id', :dependent => :destroy

end
