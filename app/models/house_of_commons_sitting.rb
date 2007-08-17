class HouseOfCommonsSitting < Sitting

  has_one :debates, :class_name => "Debates", :foreign_key => 'sitting_id'

end
