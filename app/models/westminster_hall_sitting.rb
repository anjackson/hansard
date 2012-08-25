class WestminsterHallSitting < Sitting

  class << self
    def anchor
      uri_component
    end

    def house
      'Commons'
    end

    def uri_component
      'westminster_hall'
    end

    def hansard_reference_prefix
      "HC"
    end

    def hansard_reference_suffix
      "WH"
    end
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

end
