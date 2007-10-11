class HouseOfCommonsSitting < Sitting

  def self.all_grouped_by_year
    sittings = HouseOfCommonsSitting.find(:all, :order => "date asc")
    sittings.in_groups_by { |s| s.date.year }
  end

  def self.uri_component
    'commons'
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => 1)
    xml.housecommons do
      marker_xml(options)
      xml.title(title)
      xml.date(date_text, :format => date.strftime("%Y-%m-%d"))
      xml << text + "\n"
      debates.to_xml(options) if debates
    end
  end
end
