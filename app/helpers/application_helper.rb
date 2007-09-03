require 'hpricot'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def marker_html(model, options)
    markers = ''
    model.markers(options) do |marker_type, marker_value|
      if marker_type == "image"
        markers += image_marker(marker_value)
      elsif marker_type == "column"
        markers += column_marker(marker_value)
      end
    end 
    markers
  end
  
  def image_marker(image_src)
    "<h4 class='sidenote'>Image #{image_src}</h4>"
  end
  
  def column_marker(column)
    "<h4 class='sidenote'>Col. #{column}</h4><a name='column_#{column}'>"
  end
  
  def sitting_link(sitting)
    link_to sitting.title + " &ndash; " + sitting_display_date(sitting), sitting_date_url(sitting)
  end
  
  def sitting_date_url(sitting)
    if sitting.date.day < 10
      day = "0"+sitting.date.day.to_s
    else
      day = sitting.date.day.to_s
    end
    url_for(:controller => 'commons', 
            :action => 'show_commons_hansard', 
            :year => sitting.date.year, 
            :month => Date::ABBR_MONTHNAMES[sitting.date.month].downcase, 
            :day => day)
  end
  
  def sitting_display_date(sitting)
    sitting.date.strftime("%A, %B %d, %Y")
  end
  
  def colon_after_member_name contribution
    if (!contribution.member_constituency and !contribution.procedural_note)
      ':'
    else
      ''
    end
  end

  def colon_after_constituency contribution
    if (contribution.member_constituency and !contribution.procedural_note)
      ':'
    else
      ''
    end
  end

  def format_section_title title
    title.gsub('<lb>',' ').gsub('</lb>','').squeeze(' ')
  end

  def format_contribution text, outer_elements=['p']
    if text.include? ':'
      text = text.sub(':','').strip
    end

    xml = '<wrapper>'+text+'</wrapper>'
    doc = Hpricot.XML xml
    inner_elements = []
    parts = handle_contribution_part doc.children.first, [], inner_elements, outer_elements
    '<p>'+parts.join('').squeeze(' ')+'</p>'
  end

  private

    def close_add_open parts, inner_elements, outer_elements, addition
      inner_elements.each { |e| parts << "</#{e}>" }
      parts << "</p>"
      outer_elements.each { |e| parts << "</#{e}>" }

      parts << addition

      outer_elements.reverse.each { |e| parts << "<#{e}>" }
      parts << "<p>"
      inner_elements.reverse.each { |e| parts << "<#{e}>" }
    end

    def wrap_with element, node, parts, inner_elements, outer_elements
      parts << '<'+element+'>'
      handle_contribution_part(node, parts, inner_elements + [element], outer_elements)
      parts << '</'+element+'>'
    end

    def handle_contribution_part node, parts, inner_elements, outer_elements
      node.children.each do |child|
        if child.text?
          parts << child.to_s if child.to_s.size > 0
        elsif child.elem?
          name = child.name
          if name == 'quote'
            parts << '<span class="quote">'
            handle_contribution_part(child, parts, inner_elements, outer_elements)
            parts << '</span>'
          elsif name == 'col'
            addition = column_marker(child.inner_html)
            close_add_open parts, inner_elements, outer_elements, addition
          elsif name == 'image'
            addition = image_marker(child.attributes['src'])
            close_add_open parts, inner_elements, outer_elements, addition
          elsif name == 'lb'
            parts << '</p><p>'
          elsif name == 'i'
            wrap_with 'i', child, parts, inner_elements, outer_elements
          elsif name == 'sub'
            wrap_with 'sub', child, parts, inner_elements, outer_elements
          elsif(name == 'ol' or name == 'ul')
            addition = child.to_s
            close_add_open parts, inner_elements, outer_elements, addition
          else
            # raise 'unexpected element in contribution text: ' + name
          end
        end
      end
      parts
    end

end
