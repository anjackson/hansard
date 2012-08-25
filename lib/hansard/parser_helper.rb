module Hansard
end

module Hansard::ParserHelper

  def get_root_name doc
    index = 0
    root = doc.children[index]
    while root.elem? == false
      index += 1
      root = doc.children[index]
    end
    root.name
  end

  def anchor_id
    anchor_id = "#{@source_file.name}_#{sitting.short_date}_#{sitting.type_abbreviation}_#{anchor_integer}"
    self.anchor_integer += 1
    return anchor_id
  end
  
  def date_from_filename file
    filename = File.basename(file, '.xml')
    date_patt = /(\d\d\d\d_\d\d_\d\d)/
    if match = date_patt.match(filename)
      file_date = match[1].gsub('_', '-')
      date = file_date
    end
    date
  end

  def create_section(section_type)
    section = section_type.new({
      :start_column => @column,
      :sitting => @sitting,
      :date => @sitting.date
    })
    section
  end

  def handle_quote_contribution node, section
    quote = QuoteContribution.new({
      :column_range => @column,
      :text => clean_html(node).strip,
      :xml_id => node.attributes['id'],
      :anchor_id => anchor_id,
      :start_image => @image, 
      :end_image => @image
    })
    quote.section = section
    section.contributions << quote
  end

  def set_columns_and_images_on_contribution element, contribution
    (element/'col').each do |col|
      handle_contribution_col(col, contribution)
    end
    (element/'image').each do |image|
      handle_contribution_image(image, contribution)
    end
  end

  COMMONS_PATTERN = regexp('commons')
  LORDS_PATTERN = regexp('lords')

  def house(filename)
    return 'commons' if COMMONS_PATTERN.match(filename)
    return 'lords' if LORDS_PATTERN.match(filename)
  end

  def log text
    @data_file.add_log text if @data_file
  end

  def handle_contribution_col(col, contribution)
    handle_image_or_column col
    contribution.column_range += ','+@column
  end

  def handle_contribution_image(image, contribution)
    handle_image_or_column image
    contribution.end_image = @image
  end

  def handle_contribution_text element, contribution
    set_columns_and_images_on_contribution element, contribution
    contribution.text = handle_node_text element
  end

  def handle_node_text element
    text = []
    element.children.each do |child|
      text << (child.elem? ?  child.to_original_html : child.to_s)
    end
    text = text.join('')
    text.gsub!("\r\n","\n")
    text.strip!
    text
  end

  def handle_image_or_column node
    if node.name == "col"
      @column = clean_html(node)
    end
    if node.name == 'image'
      @image = node[:src]
    end
  end

  def handle_table_element node, section, xml_id=nil
    text = clean_text(node.to_s).strip
    table = TableContribution.new({
      :column_range => @column,
      :text => text,
      :anchor_id => anchor_id,
      :start_image => @image, 
      :end_image => @image
    })

    if (id = node.attributes['id'])
      table.xml_id = id
    elsif xml_id
      table.xml_id = xml_id
    end
    table.section = section
    section.contributions << table
  end

  def clean_html node
    if node
      clean_text node.inner_html
    else
      nil
    end
  end

  def clean_text text
    chars = text.chars
    chars.gsub!("\r\n","\n")
    chars.to_s
  end

  def handle_member_name element, contribution

    element.children.each do |node|
      if node.text?
        text = node.to_s.strip
        contribution.member_name += text if text.size > 0

      elsif node.elem?
        if node.name == 'memberconstituency'
          contribution.member_suffix = clean_html(node)
        elsif node.name == 'col'
          handle_image_or_column node
          contribution.member_name += " " if !contribution.member_name.blank?
        else
          log 'unexpected element in member_name: ' + node.name + ': ' + node.to_s
        end
      end
    end
  end

  def raise_error_if_non_blank_text node, msg='unexpected text outside of section: '
    raise "#{msg} #{node.to_s}" if node.text? && !node.to_s.blank?
  end
end
