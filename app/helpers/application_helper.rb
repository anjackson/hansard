require 'hpricot'

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
    image_link = link_to "Img. #{image_src}", "/images/#{image_src}.jpg"
    "<span class='sidenote'>#{image_link}</span>"
  end
  
  def column_marker(column, extra_class="")
    "<span class='sidenote#{extra_class}'><a name='column_#{column}' href='#column_#{column}'>Col. #{column}</a></span>"
  end
  
  def section_url(section, sitting_params)
    sitting_params[:type] = sitting_params[:controller]
    url_for(sitting_params.update(:controller => "sections", 
                                  :action => "show", 
                                  :id => section.slug))
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
  
  def day_nav_links_utterly_broken
    output = "<ol id='navigation'>"
    output << "<li><a href='#{home_url}'><strong>Historic Hansard</strong></a></li>"
              
      if @day
        output << "<li><a href='" << day_link(@sitting,"<") << "'>Previous day</a></li>"
        output << "<li><a href='" << day_link(@sitting,">") << "'>Next day</a></li>"
        output << "<li><a href='#{sitting_date_source_url(@sitting)}'>XML source</a></li>"
        output << "<li><a href='#{sitting_date_xml_url(@sitting)}'>XML output</a></li>"

      else
        output << "<li><a href='#{written_answers_url}'>Written Answers</a></li>"
        output << "<li><a href='#{indices_url}'>Indices</a></li>"
        output << "<li><a href='#{source_files_url}'>Source Files</a></li>"
        output << "<li><a href='#{data_files_url}'>Data files</a></li>"
          
      end
    output << "</ol>"
    output 
  end
  
  def day_nav_links
    
    open :ol, {:id => 'navigation'} do
      
      open :li do
        open :a, { :href => home_url } do
          puts "<strong>Historic Hansard</strong>"
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
        
        open :li do
          open :a, { :href => source_files_url } do
            puts "Source Files"
          end
        end
        
        open :li do
          open :a, { :href => data_files_url } do
            puts "Data Files"
          end
        end
          
      end
    end  
  end
  
  def delicious_badge
    javascript = <<EOF
    <div id="delicious_box">
    <script type="text/javascript">
        if (typeof window.Delicious == "undefined") window.Delicious = {};
        Delicious.BLOGBADGE_DEFAULT_CLASS = 'delicious-blogbadge-line';
    </script>
    <script src="http://images.del.icio.us/static/js/blogbadge.js"></script>
    </div>
EOF
  end
  
  def google_custom_search_form    
    javascript = <<EOF
    <div id="search_box">
      <form id="searchbox_002582221602550181161:owz178jujce" action="http://www.google.com/cse">
        <input type="hidden" name="cx" value="002582221602550181161:owz178jujce" />
        <input type="hidden" name="cof" value="FORID:0" />
        <input name="q" type="text" size="40" />
        <input type="submit" name="sa" value="Search" />
      </form>
      <script type="text/javascript" src="http://www.google.com/coop/cse/brand?form=searchbox_002582221602550181161%3Aowz178jujce"></script>
    </div>
EOF
  end
  
  def sitting_link(sitting)
    link_to sitting.title.titleize + " &ndash; " + sitting_display_date(sitting), sitting_date_url(sitting)
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
    # written_answer_col = /(\s)(\d+)(w)/
    index_entry.text = create_index_links(index_entry.text, index, basic_col, HouseOfCommonsSitting)
    # index_entry.text = create_index_links(index_entry.text, index, written_answer_col, WrittenAnswersSitting)
  end

  def create_index_links(entry, index, pattern, sitting_type)
    entry.gsub!(pattern) do
      text = $1
      column = $2
      suffix = $3
      section = sitting_type.find_section_by_column_and_date_range(column, index.start_date, index.end_date)
      if section
        text += link_to(column, section_url(section, sitting_date_url_params(section.sitting)) + "#column_#{column}")
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

  def format_contribution text, outer_elements=[]
    # are we really searching the entire text here?
    # can we just strip the first char if it is a colon instead?
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
            parts << '<q class="quote">'
            handle_contribution_part(child, parts, inner_elements, outer_elements)
            parts << '</q>'
          elsif name == 'col'
            parts << column_marker(child.inner_html)
          elsif name == 'image'
            parts << image_marker(child.attributes['src'])
          elsif name == 'lb'
            #should this be a br tag? doesn't look right though...
            parts << '</p><p>'
          elsif name == 'i'
            #shouldn't be i tag, but what?
            wrap_with 'i', child, parts, inner_elements, outer_elements
          elsif name == 'sub'
            wrap_with 'sub', child, parts, inner_elements, outer_elements
          elsif(name == 'ol' or name == 'ul')
            addition = child.to_s
            close_add_open parts, inner_elements, outer_elements, addition
          elsif(name == 'table')
            parts << child.to_s
          else
            parts << "<p class='warning'>Unhandled element in contribution text: #{name}.</p>"
          end
        end
      end
      parts
    end

end
