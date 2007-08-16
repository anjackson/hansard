class Division < ActiveRecord::Base

  belongs_to :division_placeholder, :class_name => 'DivisionPlaceholder', :foreign_key => 'division_placeholder_id'
  has_many :votes

end
