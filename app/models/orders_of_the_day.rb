class OrdersOfTheDay < DebatesSection

  has_many :sections, :class_name => "OrdersOfTheDaySection", :foreign_key => 'parent_section_id'

end
