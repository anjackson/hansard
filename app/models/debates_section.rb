class DebatesSection < Section

  belongs_to :sitting
  has_many :sections

  def last_section
    sections.last
  end
end
