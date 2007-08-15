class DebateSection < DebatesSection

  has_many :contributions, :foreign_key => 'section_id'

end
