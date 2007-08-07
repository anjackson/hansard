class ProceduralSection < DebatesSection

  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'
  has_one :contribution, :class_name => "ProceduralContribution"

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
