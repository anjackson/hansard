class Vote < ActiveRecord::Base

  belongs_to :division
  alias :to_activerecord_xml :to_xml

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml << name
    if constituency
      xml.i do
        xml << "(#{constituency})"
      end 
    end
  end
end
