class MemberContribution < Contribution

  alias :to_activerecord_xml :to_xml

  def member_contribution
    text
  end

  def count_by_member= count
    @count_by_member = count
  end

  def count_by_member
    @count_by_member
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    marker_xml(options)
    xml_para(options) do
      xml.text! question_no || ""
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
