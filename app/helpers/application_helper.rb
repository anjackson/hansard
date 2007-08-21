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

  def format_member_contribution(text)
    if text.include? ':'
      text = text.sub(':','').strip
    end

    xml = '<wrapper>'+text+'</wrapper>'
    doc = Hpricot.XML xml
    parts = handle_contribution_part doc.children.first, []
    parts.join('').squeeze(' ')
  end

  private

    def handle_contribution_part node, parts
      node.children.each do |child|
        if child.text?
          parts << child.to_s if child.to_s.size > 0
        elsif child.elem?
          name = child.name
          if name == 'quote'
            parts << '<span class="quote">'
            handle_contribution_part(child, parts)
            parts << '</span>'
          end
        end
      end
      parts
    end

end
