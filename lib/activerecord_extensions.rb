class ActiveRecord::Base 

  def marker_xml(options)
    
    xml = options[:builder] ||= Builder::XmlMarkup.new
    
    images = []  
    images = text.scan(/<image src="(.*)"/) if respond_to? "text" and text
    if !images.empty?
      options[:current_image_src] = images.last[0]
    else
      if first_image_source != options[:current_image_src]    
        xml.image(:src => first_image_source)
        options[:current_image_src] = first_image_source
      end
    end
    
    text_cols = []
    text_cols = text.scan(/<col>(\d+)/) if respond_to? "text" and text
    if !text_cols.empty?
      options[:current_column] = text_cols.last[0].to_i
    else      
      if first_col != options[:current_column]
        xml.col first_col
        options[:current_column] = first_col
      end
    end
    
  end
  
end