require 'hpricot'

module ApplicationHelper

  def link_to_member(member_name)
    member = Member.new(member_name)
    link_to member.name, show_member_url(:name => member.slug)
  end
  
  def intro section
    section.introduction.text
  end

  def marker_html(section_or_contribution, options)
    markers = ''
    section_or_contribution.markers(options) do |marker_type, marker_value|
      if marker_type == "image"
        markers += image_marker(marker_value)
      elsif marker_type == "column"
        markers += column_marker(marker_value)
      end
    end
    markers.sub("</span><span class='sidenote'>", "<br />")
  end

  def image_marker(image_src)
    dummy_image = image_tag "dummypage.jpg", :border => 0
    "<span class='sidenote'><a href='/images/#{image_src}.jpg' alt='#{image_src}' title='#{image_src}' class='image-thumbnail'><figure>#{dummy_image}<br/><legend>Img. #{image_src}</legend></figure></a></span>"
  end

  def column_marker(column)
    "<span class='sidenote'><a name='column_#{column}' href='#column_#{column}'>Col. #{column}</a></span>"
  end

  def section_url(section)
    params = section.id_hash
    url_for(params.merge!(:controller => "sections", :action => "show"))
  end
  
  def lower_resolution(resolution)
    case resolution
    when :century
      :year
    when :year
      :month
    when :month
      :day
    end
  end
  
  def resolution_title(date, resolution)
    title = "Information by year"
    case resolution
      when :year
        title = "Information for #{date.year}"
      when :month
        title = "Information for #{Date::MONTHNAMES[date.month]} #{date.year}"
      when :day
        title = "Information for #{date.day} #{Date::MONTHNAMES[date.month]} #{date.year}"
    end
    title
  end
  
  def on_date_url(date_params)
    params = { :controller => 'sittings', 
               :action => 'show',
               :year => date_params[:year],
               :month => date_params[:month], 
               :day => date_params[:day] }
    url_for params
  end
  
  def sitting_nav_links(sitting)
    open :table, { :id => 'navigation-by-sittings' } do

      open :thead do
        open :th do
          puts "Hansard"
        end
      end

      open :tr do
        open :td do
          puts "This year&mdash;<br/>"
          open :a, { :class => 'sitting-year', :href => on_date_url(:year => sitting.year, :month => nil, :day => nil)} do
            puts sitting.year
          end
        end
      end

      open :tr do
        open :td do
          puts "This month&mdash;<br/>"
          open :a, { :class => 'sitting-month', :href => on_date_url(:year => sitting.year, :month => month_abbr(sitting.month), :day => nil)} do
            puts "#{month_abbr(sitting.month).titleize} #{sitting.year}"
          end
        end
      end

      open :tr do
        open :td do
          puts "This day&mdash;<br/>"
          open :a, { :class => 'sitting-day', :href => on_date_url(:year => sitting.year, :month => month_abbr(sitting.month), :day => zero_padded_day(sitting.day))} do
            puts "#{sitting.day} #{month_abbr(sitting.month).titleize} #{sitting.year}"
          end
        end
      end

      open :tfoot do
        open :td do
          open :p do
            puts "Top of page."
          end
          open :p do
            puts "&copy; UK Parliament."
          end
        end
      end
    end
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

    open :ul, { :id => 'navigation-by-links' } do

      open :li do
        open :a, { :href => home_url } do
          puts "<strong>HANSARD</strong>"
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
          open :a, { :href => sittings_url } do
            puts "By Year"
          end
        end
        
        open :li do
          open :a, { :href => commons_url } do
            puts "Commons"
          end
        end

        open :li do
          open :a, { :href => written_answers_url } do
            puts "Written Answers"
          end
        end

        open :li do
          open :a, { :href => lords_url } do
            puts "Lords"
          end
        end

        open :li do
          open :a, { :href => lords_reports_url } do
            puts "Lords Reports"
          end
        end
        
        open :li do
          open :a, { :href => parliament_sessions_url } do
            puts "Sessions"
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

  def search_form id='search', submit_text='Search', &block
    open :form, { :action => "#{search_url}", :id => id } do
      puts "<input accesskey='s' name='query' size='20' type='text' value='test'>"
      puts "<input name='sa' type='submit' value='#{submit_text}'>"
      yield if block
    end
  end

  def member_search_form member_name
    search_form('search_by_member', "Search in these results") do
      open :input, { :name => 'member', :type => 'hidden', :value => member_name }
    end
  end

  def google_custom_search_form(default_query="")
    javascript = <<EOF
    <div id="search_box">
      <form id="searchbox_002582221602550181161:owz178jujce" action="http://www.google.com/cse">
        <input type="hidden" name="cx" value="002582221602550181161:owz178jujce" />
        <input type="hidden" name="cof" value="FORID:0" />
        <input name="q" type="text" size="40" value="#{default_query}" />
        <input type="submit" name="sa" value="Search" />
      </form>
      <script type="text/javascript" src="http://www.google.com/coop/cse/brand?form=searchbox_002582221602550181161%3Aowz178jujce"></script>
    </div>
EOF
  end


  def sitting_link(sitting)
    sitting_url = sitting_date_url(sitting)

    if sitting.title
      sitting_string = sitting.title.titleize + " &ndash; " + sitting_display_date(sitting)
    else
      sitting_string = sitting_display_date(sitting)
    end
    if sitting_url
      link_to(sitting_string, sitting_date_url(sitting))
    else
      sitting_string
    end
  end

  def index_link(index)
    link_text = "#{index.start_date_text} &ndash; #{index.end_date_text}"
    url = index_date_span_url(index)
    if url
      link_to link_text, url
    else
      link_text
    end
  end

  def alphabet_links(index)
    links = []
    index_link = index_date_span_url(index)
    ('A'..'Z').each do |letter|
      links << "<a href=\"#{index_link}?letter=#{letter}\">#{letter}</a>"
    end
    links.join(' ')
  end

  def index_entry_links(index_entry)
    index_entry_index = index_entry.index
    # nasty: assumes house of commons, not correct yet, waiting for calendar
    index_entry.text.gsub! /\((\d+)\.(\d+)\.(\d+)\)/, link_to('\0', '/19\3/\2/\1')
    column_reference = /(\s)(\d+)(,|\s|&#x2013;\d+,|&#x2013;\d+$|$)/
    # written_answer_col = /(\s)(\d+)(w)/
    index_entry.text = create_index_links_for_columns(index_entry.text, index_entry_index, column_reference, HouseOfCommonsSitting)
    # index_entry.text = create_index_links(index_entry.text, index, written_answer_col, WrittenAnswersSitting)

  end

  def create_index_links_for_columns(entry, index, pattern, sitting_type)
    entry.gsub!(pattern) do
      text = $1
      column = $2
      suffix = $3
      section = sitting_type.find_section_by_column_and_date_range(column, index.start_date, index.end_date)
      if section
        text += link_to(column, section_url(section) + "#column_#{column}")
      else
        text += column
      end
      text += suffix
      text
    end
    entry
  end

  def index_date_span_url(index)
    begin
      url_for(:controller  => 'indices',
              :action      => 'show',
              :start_year  => index.start_date.year,
              :start_month => month_abbr(index.start_date.month),
              :start_day   => zero_padded_day(index.start_date.day),
              :end_year    => index.end_date.year,
              :end_month   => month_abbr(index.end_date.month),
              :end_day     => zero_padded_day(index.end_date.day))
    rescue
      nil
    end
  end

  def sitting_date_url(sitting)
    begin
      url_for(sitting_date_url_params(sitting, :action => "show"))
    rescue
      nil
    end
  end

  def edit_sitting_link(sitting)
    link_to('edit this page', edit_sitting_url(sitting))
  end

  def edit_sitting_url(sitting)
    url_for(sitting_date_url_params(sitting, :action => "edit"))
  end

  def sitting_date_source_url(sitting)
    url_for(sitting_date_url_params(sitting, :action => "show_source", :format => "xml"))
  end

  def sitting_date_xml_url(sitting)
    url_for(sitting_date_url_params(sitting, :action => "show", :format => "xml"))
  end

  def sitting_date_url_params(sitting, options)
    params = sitting.id_hash
    params.delete(:type)
    params.merge!(:controller => sitting.uri_component)
    params.merge!(options)
  end

  def sitting_controller(sitting)

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
    title.gsub('<lb>',' ').gsub('<lb/>',' ').gsub('</lb>','').squeeze(' ')
  end

  def format_time time_contribution
    %Q[<abbr class="dtstart" title="#{time_contribution.timestamp}">#{time_contribution.text}</abbr>]
  end

  def format_contribution text, outer_elements=[]
    if text.include? ':'
      text = text.sub(':','').strip
    end

    if text.include? "<quote>"
      text = text.gsub('<quote>"','<quote>').gsub('"</quote>','</quote>')
    end

    xml = '<wrapper>' + text + '</wrapper>'
    doc = Hpricot.XML xml
    inner_elements = []
    parts = handle_contribution_part doc.children.first, [], inner_elements, outer_elements
    parts = '<p>' + parts.join('').squeeze(' ') + '</p>'
    parts.gsub!(/<\/span>\s*<span class='sidenote'>/,"<br />")
    parts.sub!("&#x00B7;", ".")
    parts
  end

  def html_list(text)
    list = text.split("\n").compact
    "<ul><li>" + list.join("</li><li>") + "</li></ul>"
  end

  def html_linebreaks(text)
    text.gsub("\n", "<br />")
  end

  def xsd_valid source_file
    if source_file.xsd_validated.nil?
      '&mdash;'
    elsif source_file.xsd_validated
      'Y'
    else
      'N'
    end
  end

  def xsd_valid_message source_file
    if source_file.xsd_validated.nil?
      'validation not yet performed'
    elsif source_file.xsd_validated
      'valid to schema'
    else
      'not valid to schema'
    end
  end

  def section_nesting_buttons section
    if section.can_be_nested?
      if section.can_be_unnested?
        section_unnest_button(section) + ' ' + section_nest_button(section)
      else
        section_nest_button(section)
      end
    elsif section.can_be_unnested?
      section_unnest_button(section)
    else
      nil
    end
  end

  private

    def section_nest_button section
      params = section.id_hash.merge(:action => 'nest', :controller => 'sections')
      button_to('->', params).gsub('div','span')
    end

    def section_unnest_button section
      params = section.id_hash.merge(:action => 'unnest', :controller => 'sections')
      button_to('<-', params).gsub('div','span')
    end

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
          elsif name == 'b'
            wrap_with 'b', child, parts, inner_elements, outer_elements
          elsif name == 'sub'
            wrap_with 'sub', child, parts, inner_elements, outer_elements
          elsif(name == 'ol' or name == 'ul')
            addition = child.to_s
            list_has_numbering = /<li>\d+\. /.match addition
            if list_has_numbering
              addition.sub!('<ol','<ol class="hide_numbering"')
            end
            close_add_open parts, inner_elements, outer_elements, addition
          elsif(name == 'table')
            parts << child.to_s
          elsif name == 'sup'
            wrap_with 'sup', child, parts, inner_elements, outer_elements
          elsif name == 'member'
            parts << '<span class="member">'
            handle_contribution_part(child, parts, inner_elements, outer_elements)
            parts << '</span>'
          else
            parts << "<p class='warning'>Unhandled element in contribution text: #{name}.</p>"
          end
        end
      end
      parts
    end

end
