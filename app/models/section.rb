class Section < ActiveRecord::Base

  has_many :contributions
  has_many :sections, :foreign_key => 'parent_section_id'
  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'

end
