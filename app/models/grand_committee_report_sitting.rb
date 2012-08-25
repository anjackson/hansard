class GrandCommitteeReportSitting < Sitting

  has_one :section, :foreign_key => "sitting_id", :dependent => :destroy

  def self.anchor
    self.uri_component
  end

  def self.uri_component
    'grand_committee_report'
  end

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new(:indent => 1)
    xml.grandcommitteereport do
      marker_xml(options)
      xml.title(title)
      xml.date(date_text, :format => date.strftime("%Y-%m-%d"))
      debates.to_xml(options) if debates
    end
  end

  def top_level_sections
    [section]
  end
  
  def self.house
    'Lords'
  end

  protected

    def self.hansard_reference_prefix
      "HL"
    end

    def self.hansard_reference_suffix
      "GC"
    end
end
