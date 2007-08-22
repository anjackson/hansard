class Contribution < ActiveRecord::Base

  belongs_to :section
  alias :to_activerecord_xml :to_xml

  def to_xml(options={})
    xml = options[:builder] ||= Builder::XmlMarkup.new
    xml_markers(options)
    style_hash = {}
    if style
      style.split(" ").each do |style|
        key, value = style.split('=')
        style_hash[key] = value
      end
    end
    xml.p style_hash.update(:id => xml_id) do 
      xml << text if text 
    end
  end
  
  def xml_markers(options)
    xml = options[:builder] ||= Builder::XmlMarkup.new
    images = []
    images = text.scan(/<image src="(.*)"/) if text
    if !images.empty?
      options[:current_image_src] = images.last[0]
    else
      if first_image_source != options[:current_image_src]
        xml.image(:src => first_image_source)
        options[:current_image_src] = first_image_source
      end
    end
    
    text_cols = []
    text_cols = text.scan(/<col>(\d+)/) if text
    if !text_cols.empty?
      options[:current_column] = text_cols.last[0].to_i
    else
      if first_col > options[:current_column]
        xml.col(first_col)
        options[:current_column] = first_col
      end
    end  
  end
  
  def cols
     column_range ? column_range.split(",").map{ |col| col.to_i } : []
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

end
