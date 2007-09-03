class OralQuestions < Section

  has_many :sections, :class_name => "OralQuestionsSection", :foreign_key => 'parent_section_id', :dependent => :destroy

  def outer_tag(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.oralquestions do
      yield
    end
  end

end
