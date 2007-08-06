class HouseOfCommonsSitting < Sitting

  has_one :debates, :class_name => "Section"

end
