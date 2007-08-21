class DivisionPlaceholder < Contribution

  has_one :division, :foreign_key => 'division_placeholder_id'
  
  def to_xml(options={})
    division.to_xml(options)
  end

end
