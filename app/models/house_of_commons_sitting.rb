class HouseOfCommonsSitting < Sitting

  def self.anchor
    self.uri_component
  end

  def self.house
    'Commons'
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
      debates.to_xml(options) if debates
    end
  end

  protected

    def self.hansard_reference_prefix
      "HC"
    end

    def self.hansard_reference_suffix
      ""
    end
end
