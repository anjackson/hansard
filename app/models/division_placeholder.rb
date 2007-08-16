class DivisionPlaceholder < Contribution

  has_one :division, :foreign_key => 'division_placeholder_id'

end
