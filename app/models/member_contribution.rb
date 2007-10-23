class MemberContribution < Contribution

  alias :to_activerecord_xml :to_xml

  def self.find_all_members
    sql = %Q[select distinct member, count(member) AS count_by_member from contributions where (type = 'MemberContribution' or type = 'WrittenMemberContribution') group by member;]
    contributions = self.find_by_sql(sql)
    contributions.collect do |c|
      Member.new(c.plain_member_name, c.attributes['count_by_member'])
    end
  end

  def plain_member_name
    if member
      member.gsub(/<lb>|<\/lb>|<lb\/>/,'').squeeze(' ')
    end
  end

  def member_contribution
    text
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

  private

    def count_by_member= count
      @count_by_member = count
    end

    def count_by_member
      @count_by_member
    end

end
