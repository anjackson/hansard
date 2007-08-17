class Contribution < ActiveRecord::Base

  belongs_to :section
  alias :to_activerecord_xml :to_xml

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml
  end

end
