class HouseOfCommonsSitting < Sitting

  has_one :debates, :class_name => "Debates", :foreign_key => "sitting_id"
  alias :to_activerecord_xml :to_xml
  
  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.housecommons do
      xml.image(:src => start_image_src)
      xml.col(start_column)
      xml.title(title)
      xml.date(date_text, :format => date.strftime("%Y-%m-%d"))
      xml << text
      debates.to_xml(options) if debates
    end
  end
end
