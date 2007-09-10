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
    "<h4 class='sidenote'><img src='/images/dummypage.jpg' alt='Image: #{image_src}' title='Image: #{image_src}'/></h4>"
  end
  
  def column_marker(column, extra_class="")
    "<h4 class='sidenote#{extra_class}'>Col. #{column}</h4><a name='column_#{column}'>"
  end
  
  def day_link(sitting, direction)
    next_sitting = sitting.class.find_next(sitting.date, direction)
    if next_sitting
      open :a, { :href => sitting_date_url(next_sitting) } do
        yield
      end
    else
      yield
    end
  end
  
  def day_nav_links
    
    open :ol, {:id => 'navigation'} do
      
      open :li do
        open :a, { :href => home_url } do
          puts "Historic Hansard"
        end
      end
        
      if @day
     
        open :li do   
          day_link(@sitting,"<"){ puts "Previous day" }
        end
     
        open :li do   
          day_link(@sitting, ">"){ puts "Next day" }
        end
        
        open :li do
          open :a, { :href => sitting_date_source_url(@sitting) } do
            puts "XML source"
          end
        end
        
        open :li do
          open :a, { :href => sitting_date_xml_url(@sitting) } do
            puts "XML output"
          end 
        end
        
      else
        open :li do
          open :a, { :href => written_answers_url } do
            puts "Written Answers"
          end
        end
          
        open :li do
          open :a, { :href => indices_url } do
            puts "Indices"
          end
        end      
      end
    end  
  end
  
  
  def sitting_link(sitting)
    link_to sitting.title + " &ndash; " + sitting_display_date(sitting), sitting_date_url(sitting)
  end
  
  def index_link(index)
    link_text = "#{index.start_date_text} &ndash; #{index.end_date_text}"
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
    index = index_entry.index
    basic_col = /(\s)(\d+)(,|\s|&#x2013;\d+,|&#x2013;\d+$|$)/
    written_answer_col = /(\s)(\d+)(w)/
    index_entry.text = create_index_links(index_entry.text, index, basic_col, HouseOfCommonsSitting)
    index_entry.text = create_index_links(index_entry.text, index, written_answer_col, WrittenAnswersSitting)
  end

  def create_index_links(entry, index, pattern, sitting_type)
    entry.gsub!(pattern) do
      text = $1
      column = $2
      suffix = $3
      sitting = sitting_type.find_by_column_and_date_range(column, index.start_date, index.end_date)
      if sitting
        text += link_to(column, sitting_date_url(sitting) + "#column_#{column}")
      else
        text += column
      end
      text += suffix
      text
    end
    entry
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
    url_for(sitting_date_url_params(sitting))
  end
  
  def sitting_date_source_url(sitting)
    source_params = {:action => "show_source", 
                     :format => "xml"}
    url_for(sitting_date_url_params(sitting).update(source_params))
  end
  
  def sitting_date_xml_url(sitting)
    url_for(sitting_date_url_params(sitting).update(:format => "xml"))
  end
  
  def sitting_date_url_params(sitting)
    {:controller => sitting_controller(sitting),
     :action     => "show",
     :year       => sitting.date.year, 
     :month      => month_abbr(sitting.date.month), 
     :day        => zero_padded_day(sitting.date.day)}
  end
  
  def sitting_controller(sitting)
    case sitting
    when HouseOfCommonsSitting
      'commons'
    when WrittenAnswersSitting
      'written_answers'
    else 
      raise "Can't generate a url for '#{sitting.class}"
    end
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
  
  def html_list(text)
    list = text.split("\n").compact
    "<ul><li>" + list.join("</li><li>") + "</li></ul>"
  end

  def html_linebreaks(text)
    text.gsub("\n", "<br>")
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
