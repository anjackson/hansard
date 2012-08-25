class Vote < ActiveRecord::Base

  belongs_to :division
  alias :to_activerecord_xml :to_xml
  acts_as_hansard_element

  def self.is_teller?
    name.include?('Teller')
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml << name.to_xs
    if constituency
      xml.i do
        xml << "(#{constituency.to_xs})"
      end
    end
  end

  def start_column
    column ? column.to_i : nil
  end
  
  def end_column
    column ? column.to_i : nil
  end

end
