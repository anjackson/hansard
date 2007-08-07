class ProceduralSection < Section

  belongs_to :section
  has_one :contribution

  def text= value
    self.contribution = ProceduralContribution.new unless self.contribution
    self.contribution.text = value
  end

  def xml_id= value
    self.contribution = ProceduralContribution.new unless self.contribution
    self.contribution.xml_id = value
  end

  def text
    contribution.text
  end

  def xml_id
    contribution.xml_id
  end
end
