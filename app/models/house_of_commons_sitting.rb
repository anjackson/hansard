class HouseOfCommonsSitting < Sitting

  has_one :debates, :class_name => "Debates"

end
