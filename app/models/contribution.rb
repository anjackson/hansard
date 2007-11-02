class Contribution < ActiveRecord::Base

  belongs_to :section
  alias :to_activerecord_xml :to_xml
  acts_as_hansard_element
  acts_as_solr :fields => [:text , {:member_name => :facet}, {:date => :facet}], :facets => [:member_name, {:date => :date}]

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    marker_xml(options)
    xml_para(options) do
      xml << text if text
    end
  end

  def year
    date.year
  end

  def date
    section.date
  end

  def word_count
    self.text.split(" ").length
  end

  def cols
     column_range ? column_range.split(",").map{ |col| col.to_i.nonzero? ? col.to_i : col } : []
  end

  def image_sources
     image_src_range ? image_src_range.split(",").map{ |image_src| image_src } : []
  end

  def first_image_source
    image_sources.empty? ? nil : image_sources.first
  end

  def last_image_source
    image_sources.empty? ? nil : image_sources.last
  end

  def first_col
    cols.empty? ? nil : cols.first
  end

  def last_col
    cols.empty? ? nil : cols.last
  end

  def xml_para(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    attribute_hash = {}
    if style
      style.split(" ").each do |style|
        key, value = style.split('=')
        attribute_hash[key] = value
      end
    end
    attribute_hash.update(:id => xml_id) if xml_id
    xml.p(attribute_hash) do
      yield
    end
  end

end
