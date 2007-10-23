class WrittenMemberContribution < MemberContribution

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    marker_xml(options)
    xml_para(options) do
      xml.text! question_no || ""
      xml.member do
        xml << member.strip
        xml.memberconstituency(member_constituency) if member_constituency
      end
      xml << text.strip if text
    end
  end

end
