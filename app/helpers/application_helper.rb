require 'hpricot'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

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

  def format_member_contribution text, outer_element='p'
    if text.include? ':'
      text = text.sub(':','').strip
    end

    xml = '<wrapper>'+text+'</wrapper>'
    doc = Hpricot.XML xml
    parts = handle_contribution_part doc.children.first, [], outer_element
    '<p>'+parts.join('').squeeze(' ')+'</p>'
  end

  private

    def handle_contribution_part node, parts, outer_element
      node.children.each do |child|
        if child.text?
          parts << child.to_s if child.to_s.size > 0
        elsif child.elem?
          name = child.name
          if name == 'quote'
            parts << '<span class="quote">'
            handle_contribution_part(child, parts, outer_element)
            parts << '</span>'
          elsif name == 'col'
            parts << "</p></#{outer_element}>"
            parts << "<h4>Column #{child.inner_html}</h4>"
            parts << "<#{outer_element}><p>"
          elsif name == 'image'
            parts << "</p></#{outer_element}>"
            parts << "<h4>Image #{child.attributes['src']}</h4>"
            parts << "<#{outer_element}><p>"
          elsif name == 'lb'
            parts << '</p><p>'
          elsif name == 'i'
            parts << '<i>'
            handle_contribution_part(child, parts, outer_element)
            parts << '</i>'
          else
            raise 'unexpected element in contribution text: ' + name
          end
        end
      end
      parts
    end

end
