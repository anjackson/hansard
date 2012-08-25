class WrittenStatementsSitting < Sitting

  has_many :groups, :class_name => "WrittenStatementsGroup", :foreign_key => "sitting_id", :dependent => :destroy

  alias :to_activerecord_xml :to_xml

  def self.uri_component
    'written_statements'
  end

  def each_section
    all_sections.each do |section|
      yield section
    end
  end

  def top_level_sections
    groups
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => 1)
    xml.writtenanswers do
      marker_xml(options)
      xml.title do
        xml << title.to_xs if title
      end
      xml.date(date_text, :format => date.strftime("%Y-%m-%d"))
      if groups
        groups.each do |group|
          group.to_xml(options)
        end
      end
    end
  end

  # These STI subclasses need to be loaded explicitly or they aren't included in finders
  require_association 'commons_written_statements_sitting'
  require_association 'lords_written_statements_sitting'

end
