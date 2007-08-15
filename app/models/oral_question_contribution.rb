class OralQuestionContribution < MemberContribution

  belongs_to :section, :class_name => "OralQuestionSection", :foreign_key => 'section_id'
  alias :to_activerecord_xml :to_xml

  def member_contribution
    text
  end
  
  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.p(:id => xml_id) do
      xml.text! oral_question_no || ""
      xml.member
      xml.membercontribution text
    end
  end

end
