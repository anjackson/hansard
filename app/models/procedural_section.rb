class ProceduralSection < DebatesSection

  has_many :contributions, :class_name => "ProceduralContribution"

end
