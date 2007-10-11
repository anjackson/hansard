class WrittenAnswersSitting < Sitting

  has_many :groups, :class_name => "WrittenAnswersGroup", :foreign_key => "sitting_id", :dependent => :destroy

  alias :to_activerecord_xml :to_xml

  def self.uri_component
    'written_answers'
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => 1)
    xml.writtenanswers do
      marker_xml(options)
      xml.title do
        xml << title
      end
      xml.date(date_text, :format => date.strftime("%Y-%m-%d"))
      xml << text + "\n"
      if groups
        groups.each do |group|
          group.to_xml(options)
        end
      end
    end
  end
end
