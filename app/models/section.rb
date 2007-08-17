class Section < ActiveRecord::Base

  has_many :contributions
  has_many :sections, :foreign_key => 'parent_section_id'
  belongs_to :parent_section, :class_name => "Section", :foreign_key => 'parent_section_id'
  alias :to_activerecord_xml :to_xml

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml.title(title)
    contributions.each do |contribution|
      contribution.to_xml(options)
    end
    sections.each do |section|
      section.to_xml(options)
    end
    xml
  end
  
end
