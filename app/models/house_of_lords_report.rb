class HouseOfLordsReport < Sitting

  def self.anchor
    self.uri_component
  end

  def self.uri_component
    'lords_reports'
  end
  
  def self.house
    'Lords'
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => 1)
    xml.houselords do
      marker_xml(options)
      xml.title(title)
      xml.date(date_text, :format => date.strftime("%Y-%m-%d"))
      debates.to_xml(options) if debates
    end
  end
end
