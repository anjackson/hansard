class HouseOfLordsSitting < Sitting

  def self.uri_component
    'lords'
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => 1)
    xml.houselords do
      marker_xml(options)
      xml.title(title)
      xml.date(date_text, :format => date.strftime("%Y-%m-%d"))
      xml << text + "\n"
      debates.to_xml(options) if debates
    end
  end
end
