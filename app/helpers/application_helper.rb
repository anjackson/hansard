require 'hpricot'

# Methods added to this helper will be available to all templates in the application.
module ApplicationHelper

  def marker_html(model, options)
    markers = ''
    model.markers(options) do |marker_type, marker_value|
      if marker_type == "image"
        markers += image_marker(marker_value)
      elsif marker_type == "column"
        markers += column_marker(marker_value, extra_class=" second-sidenote")
      end
    end 
    markers
  end
  
  def image_marker(image_src)
    "<h4 class='sidenote'>Image #{image_src}</h4>"
  end
  
  def column_marker(column, extra_class="")
    "<h4 class='sidenote#{extra_class}'>Col. #{column}</h4><a name='column_#{column}'>"
  end
  
  def sitting_link(sitting)
    link_to sitting.title + " &ndash; " + sitting_display_date(sitting), sitting_date_url(sitting)
  end
  
  def index_link(index)
    link_text = "#{index.title} #{index.start_date_text} &ndash; #{index.end_date_text}"
    link_to link_text, index_date_span_url(index)
  end
  
  def alphabet_links(index)
    links = []
    index_link = index_date_span_url(index)
    ('A'..'Z').each do |letter|
      links << "<a href=\"#{index_link}?letter=#{letter}\">#{letter}</a>" 
    end
    links.join(" ")
  end
  
  def index_entry_links(index_entry)
    simple_column_number = /(\s)(\d+)(,|\s|&#x2013;\d+,|&#x2013;\d+$|$)/
    index_entry.text.gsub!(simple_column_number) do 
       text = $1
       column = $2
       suffix = $3
       index = index_entry.index
       sitting = Sitting.find_by_column_and_date_range(column, index.start_date, index.end_date)
       text += link_to(column, sitting_date_url(sitting) + "#column_#{column}")
       text += suffix
       text
    end
    index_entry.text
  end
  
  def index_date_span_url(index)
    url_for(:controller  => 'indices', 
            :action      => 'show',
            :start_year  => index.start_date.year,
            :start_month => month_abbr(index.start_date.month),
            :start_day   => zero_padded_day(index.start_date.day),
            :end_year    => index.end_date.year,
            :end_month   => month_abbr(index.end_date.month),
            :end_day     => zero_padded_day(index.end_date.day))
  end
  
  def sitting_date_url(sitting)
    url_for(:controller => 'commons', 
            :action     => 'show_commons_hansard', 
            :year       => sitting.date.year, 
            :month      => month_abbr(sitting.date.month), 
            :day        => zero_padded_day(sitting.date.day))
  end
  
  def month_abbr(month)
    Date::ABBR_MONTHNAMES[month].downcase
  end
  
  def zero_padded_day(day)
    day < 10 ? "0"+ day.to_s : day.to_s
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
