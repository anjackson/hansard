class MemberContribution < Contribution

  alias :to_activerecord_xml :to_xml

  def member_contribution
    text
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    marker_xml(options)
    xml_para(options) do
      xml.text! question_no || ""
      xml.member do
        xml << member_name.strip.to_xs
        xml.memberconstituency(constituency_name) if constituency_name
        xml.memberparty(party_name) if party_name
      end
      xml.membercontribution do
        xml << text.to_xs.strip if text
      end
    end
  end

end
