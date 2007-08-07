class HouseOfCommonsSitting < Sitting

  has_one :debates, :class_name => "DebatesSection"

end
