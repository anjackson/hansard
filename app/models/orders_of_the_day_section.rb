class OrdersOfTheDaySection < Section

  belongs_to :parent_section, :class_name => "OrdersOfTheDay", :foreign_key => 'parent_section_id'
  has_many :contributions, :class_name => "ProceduralContribution", :foreign_key => 'section_id', :order => "xml_id"

end
