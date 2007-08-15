class DebatesSection < Section

  belongs_to :parent_section, :class_name => "Debates", :foreign_key => 'parent_section_id'

end
