class HouseOfCommonsSitting < Sitting

  has_one :debates, :class_name => "Debates", :foreign_key => "sitting_id"
  alias :to_activerecord_xml :to_xml
  
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
