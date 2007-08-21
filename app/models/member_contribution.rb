class MemberContribution < Contribution

  alias :to_activerecord_xml :to_xml

  def member_contribution
    text
  end
  
  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    
    xml.p(:id => xml_id) do
      xml.text! oral_question_no || ""
      xml.member do
        xml << member.strip
        xml.memberconstituency(member_constituency) if member_constituency
      end
      xml.membercontribution do
        xml << text.strip if text
      end
    end
  end

end
