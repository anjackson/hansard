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
    doc.children.first.children.each do |node|

    end
    doc.children.first.inner_html
  end
end
