class Debates < Section

  belongs_to :sitting
  alias :to_activerecord_xml :to_xml
  has_many :sections, :class_name => "Section", :foreign_key => 'parent_section_id'

  def oral_questions
    sections.select {|s| s.is_a? OralQuestions}[0]
  end

  def outer_tag(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.debates do
      yield
    end
  end
  
  def title_xml(options)
  end
  
end
