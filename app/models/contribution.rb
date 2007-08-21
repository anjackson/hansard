class Contribution < ActiveRecord::Base

  belongs_to :section
  alias :to_activerecord_xml :to_xml

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.p :id => xml_id do 
      xml << text if text 
    end
  end
  
  def cols
     column_range ? column_range.split(",").map{ |col| col.to_i } : []
  end

  def image_sources
     image_src_range ? image_src_range.split(",").map{ |image_src| image_src } : []
  end
  
end
