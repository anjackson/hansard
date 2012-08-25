module ApplicationHelper
  
  def is_home? 
    request.url == home_url
  end
  
  def default_time_feeds
    DEFAULT_FEEDS.each do |years| 
      puts auto_discovery_link_tag(:atom, "#{years_ago_url(:years => years, :format => 'xml')}", {:title => "#{years} years ago"})
    end
  end
  
  def body_class sitting_class
    if sitting_class.name.to_s =~ /Class$/
      "page"
    else
      sitting_class.to_s.underscore.dasherize
    end
  end

  def sitting_keyword_with_comma sitting_class
    if sitting_class.name.to_s =~ /Class$/
      ''
    else
      ', ' << sitting_class.to_s.titleize.gsub(/Of/, 'of').gsub(/Sitting/, 'sitting')
    end
  end

  def is_production_env?
    RAILS_ENV == 'production'
  end

  def params_without(to_remove)
    param_hash = params
    if to_remove.is_a? Array
      to_remove.each do |key|
        param_hash = remove_key(key, param_hash)
      end
    else
      param_hash = remove_key(to_remove, param_hash)
    end
    param_hash
  end

  def remove_key(key, hash)
    key = key.to_s
    hash.reject{|k,v| k==key}
  end

  def format_page_title title
    if params[:home_page]
      title = "HANSARD 1803&ndash;2005"
    else
      return nil unless title
      title = strip_tags(title.sub('<lb>', ' <lb>'))
      if @section
        title = title + " (Hansard, #{format_date(@section.date, :day)})"
      else
        title = title + " (Hansard)"
      end
      title.gsub!(",,",",")
      title.to_s
    end
    title
  end

  def current_url
    "http://#{request.host_with_port}#{request.path}"
  end

  def timeline_options(resolution, sitting_type)
    options = { :upper_nav_limit => LAST_DATE,
                :lower_nav_limit => FIRST_DATE,
                :first_of_month => false,
                :navigation => true,
                :sitting_type => sitting_type }
    options
  end

  def link_to_section section
    link_to section.title, section_url(section)
  end

  def section_contribution_link contribution, section
    url = section_contribution_url(contribution, section)
    if contribution
      return link_to(contribution.title_via_associations, url)
    else
      return link_to(section.title, url)
    end
  end

  def section_contribution_url(contribution, section)
    url = section_url(section)
    url += "##{contribution.anchor_id}" if contribution
    url
  end

  def link_to_constituency(constituency, text)
    link_to text, constituency_url(constituency), :title => constituency.name
  end

  def person_cite_attribute person
    person ? {:cite => person_url(person)} : {}
  end

  def hcard_person(person)
    hcard = ''
    if Person.find_title(person.name)
      hcard += "<span class='title'>#{person.honorific}</span> "
      hcard += "<span class='family-name'>#{person.lastname}</span>"
    else
      hcard += "<span class='honorific-prefix'>#{person.honorific}</span > "
      hcard += "<span class='given-name'>#{person.firstname}</span> "
      hcard += "<span class='family-name'>#{person.lastname}</span>"
    end
    return "<span class='fn'>#{hcard}</span>"
  end

  def date_params_title(date_params)
    resolution_prefix(date_params[:resolution], Sitting) + format_date_params(date_params)
  end

  def resolution_prefix(resolution, sitting_type)
    sitting_string = sitting_prefix(sitting_type)
    prefix = case resolution
      when nil
        "#{sitting_string.pluralize} in the "
      when :decade
        "#{sitting_string.pluralize} in the "
      when :year
        "#{sitting_string.pluralize} in "
      when :month
        "#{sitting_string.pluralize} in "
      when :day
        "#{sitting_string.singularize} of "
    end
    prefix
  end

  def sitting_prefix sitting_type
    if sitting_type == Sitting
      "Sitting"
    elsif [HouseOfLordsSitting, HouseOfCommonsSitting, WestminsterHallSitting].include? sitting_type
      "#{sitting_type.sitting_type_name} Sitting"
    elsif [CommonsWrittenAnswersSitting, CommonsWrittenStatementsSitting, LordsWrittenAnswersSitting, LordsWrittenStatementsSitting].include? sitting_type
      "#{sitting_type.sitting_type_name} (#{sitting_type.house})"
    else
      sitting_type.sitting_type_name.singularize
    end
  end

  def resolution_title(sitting_type, date, resolution)
    resolution_prefix(resolution, sitting_type) + format_date(date, resolution)
  end

  def get_years_and_yymmdd sitting
    return [nil, nil] unless sitting.volume
    start_year = sitting.volume.session_start_year
    end_year = sitting.volume.session_end_year
    return [nil, nil] unless start_year and end_year
    years = "#{start_year}#{end_year.to_s[2..3]}"
    yymmdd = "#{sitting.year.to_s[2..3]}#{zero_padded_digit(sitting.month)}#{zero_padded_digit(sitting.day)}"
    return years, yymmdd
  end

  def parliament_uk_base_url
    'http://www.publications.parliament.uk/pa'
  end

  def link_to_lords_at_parliament_uk sitting, anchor
    if sitting.date >= Date.new(1995, 11, 15)
      years, yymmdd = get_years_and_yymmdd sitting
      return nil unless years and yymmdd
      two_letters = (sitting.date >= Date.new(2006,11,15)) ? 'cm' : 'vo'
      "#{parliament_uk_base_url}/ld#{years}/ldhansrd/#{two_letters}#{yymmdd}/index/#{yymmdd[1..5]}-x.htm#{anchor}"
    else
      nil
    end
  end

  def link_to_commons_at_parliament_uk sitting, type, type2
    years, yymmdd = get_years_and_yymmdd sitting
    return nil unless years and yymmdd
    if sitting.date > Date.new(1995, 11, 8)
      "#{parliament_uk_base_url}/cm#{years}/cmhansrd/vo#{yymmdd}/#{type}/#{yymmdd[1..5]}-x.htm"
    elsif type2 && (sitting.date >= Date.new(1988,11,22) )
      type2 = 'Orals' if (type2 == 'Debate' && sitting.debates && sitting.debates.oral_questions)
      "#{parliament_uk_base_url}/cm#{years}/cmhansrd/#{sitting.date.to_s}/#{type2}-1.html"
    else
      nil
    end
  end

  def link_to_parliament_uk sitting
    url = case sitting
      when HouseOfLordsSitting
        link_to_lords_at_parliament_uk sitting, ''
      when LordsWrittenAnswersSitting
        link_to_lords_at_parliament_uk sitting, '#start_written'
      when LordsWrittenStatementsSitting
        link_to_lords_at_parliament_uk sitting, '#start_minist'
      when HouseOfCommonsSitting
        link_to_commons_at_parliament_uk sitting, 'debindx', 'Debate'
      when CommonsWrittenAnswersSitting
        link_to_commons_at_parliament_uk sitting, 'index', 'Writtens'
      when CommonsWrittenStatementsSitting
        link_to_commons_at_parliament_uk sitting, 'wmsindx', nil
      when WestminsterHallSitting
        link_to_commons_at_parliament_uk sitting, 'hallindx', nil
      else
        nil
    end
    url ? link_to(' <small>[Official site]</small>',url) : ''
  end

  def link_to_sitting_anchor sitting
    link_to(sitting_prefix(sitting.class), "##{sitting.anchor}")
  end

  def month_string date, options={}
    options[:brief] ? "#{month_abbr(date.month).titleize}." : Date::MONTHNAMES[date.month]
  end

  def format_date(date, resolution, options={})
    case resolution
      when :decade
        "#{date.decade_string}"
      when :year
        "#{date.year}"
      when :month
        "#{month_string(date,options)} #{date.year}"
      when :day
        "#{date.day} #{month_string(date,options)} #{date.year}"
      else
        "#{date.century_ordinal} century"
    end
  end

  def format_date_params(date_params)
    formatted_date = []
    formatted_date << date_params[:day] if date_params[:day]
    formatted_date << date_params[:month].titlecase if date_params[:month]
    formatted_date << date_params[:year] if date_params[:year]
    return formatted_date.join(' ')
  end

  def month_abbr(month)
    Date::ABBR_MONTHNAMES[month].downcase
  end

  def url_for_date(date)
    on_date_url({:year => date.year,
                 :month => month_abbr(date.month),
                 :day => zero_padded_digit(date.day)})
  end

  def on_date_url(date_params)
    sitting_type = date_params[:sitting_type] || Sitting
    if date_params[:year] and date_params[:month] and date_params[:day]
      action = "show"
    else
      action = "index"
    end
    params = { :controller => sitting_type.uri_component,
               :action => action }
    if date_params[:century]
      params.update(:century => date_params[:century])
    elsif date_params[:decade]
      params.update(:decade => date_params[:decade])
    elsif date_params[:year]
      params.update(:year => date_params[:year],
                    :month => date_params[:month],
                    :day => date_params[:day])
    else
      params.update(:century => nil, :decade => nil, :year => nil)
    end
    url_for params
  end

  def make_link css_class, url
    haml_tag :a, { :class => css_class, :href => url} do
      yield
    end
  end

  def resource_breadcrumbs(model_instance, resource_name_method)
    index_link(model_instance, resource_name_method)
  end
  
  def index_link(model_instance, resource_name_method, text=nil, anchor=nil)
    resource_name_method = :name unless resource_name_method
    type = model_instance.class.name.downcase.pluralize
    name = model_instance.send(resource_name_method)
    letter = first_letter(name)
    url = send("#{type}_url".to_sym, :letter => letter)
    url += "##{anchor}" if anchor
    text = "#{type.capitalize} (#{letter.upcase})" unless text
    make_link type, url do
      puts text
    end
  end

  def first_letter(string)
    letter_pattern = /^.*?([A-Za-z])/
    if letter_match = letter_pattern.match(string)
      return letter_match[1].downcase 
    else
      return nil
    end    
  end
  
  def sitting_breadcrumbs(sitting_type, date, resolution=:day)
    if resolution == :day || resolution == :month || resolution == :year
      make_link 'sitting-decade', on_date_url(:decade => "#{date.decade}s" ) do
        puts format_date(date, :decade)
      end
    end
    if resolution == :day || resolution == :month
      puts " &rarr;"
      make_link 'sitting-year', on_date_url(:year => date.year) do
        puts format_date(date, :year)
      end
    end
    if resolution == :day
      puts " &rarr;"
      make_link 'sitting-month', on_date_url(:year => date.year, :month => month_abbr(date.month)) do
        puts format_date(date, :month, {:brief => false})
      end
      puts " &rarr;"
      make_link 'sitting-day',url_for_date(date) do
        puts format_date(date, :day, {:brief => false})
      end
    end
  end

  def day_navigation(sitting_type, date)
    day_navigation_link(sitting_type, date, ">", "Forward to", "Next")
    day_navigation_link(sitting_type, date, "<", "Back to", "Previous")
  end

  def day_navigation_link(sitting_type, date, direction, text, link_text)
    sitting = sitting_type.find_next(date, direction)
    if sitting and sitting.date >= FIRST_DATE and sitting.date <= LAST_DATE
      puts "<span class='#{link_text.downcase}-sitting-day'>"
      puts "<span class='sitting-day'>#{link_text} sitting day</span>"
      puts link_to(sitting.date.to_s(:long), url_for_date(sitting.date))
      puts "</span>"
    end
  end
  
  def haml_search form_id, accesskey, query=nil, alt_text='Search', disabled=false
    escaped_query = HTMLEntities.new.encode(query, :named)
    disable = disabled ? "disabled='true'" : ""
    haml_tag :form, { :action => "#{search_url}", :method => "post", :id => form_id, :rel=>"search" } do
      puts "<input size='24' title='Access key: #{accesskey.upcase}' accesskey='#{accesskey}' name='query' id='#{form_id}-query' type='search' placeholder='Search Hansard' autosave='#{request.host_with_port}' results='10' value='#{escaped_query or ''}' #{disable}>"
      yield
      puts "<input type='submit' value='#{alt_text}' #{disable}>"
    end
  end

  def search_form
    haml_search('search', 's', @query){}
  end

  def speaker_search_form person, disabled=false
    haml_search("person-search", 'm', nil, 'Search in speeches by this person', disabled) do
      puts "<input type='hidden' name='speaker' value='#{person.slug}'>"
    end
  end
  
  def timeline_search_form params
    haml_search('timeline-search', 't', nil, 'Search in this period') do 
      puts "<input type='hidden' name='century' value='#{params[:century]}'>" if params[:century]
      puts "<input type='hidden' name='decade' value='#{params[:decade]}'>" if params[:decade]
      if params[:year] and params[:month]
        month_integer = Date::ABBR_MONTHNAMES.index(params[:month].capitalize)
        puts "<input type='hidden' name='month' value='#{params[:year]}-#{month_integer}'>"
      elsif params[:year]
        puts "<input type='hidden' name='year' value='#{params[:year]}'>" if params[:year]
      end
    end
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

  def sitting_date_url(sitting)
    begin
      url_for(sitting_date_url_params(sitting, :action => "show"))
    rescue
      nil
    end
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

  def sitting_display_date(sitting)
    sitting.date.strftime("%A, %B %d, %Y")
  end

  def format_time time_contribution
    %Q[<a href="##{time_contribution.timestamp}" name="#{time_contribution.timestamp}"><abbr class="dtstart" title="#{time_contribution.timestamp}">#{time_contribution.text}</abbr></a>]
  end

  def html_list(text)
    list = text.split("\n").compact
    "<ul><li>" + list.join("</li><li>") + "</li></ul>"
  end

  def html_linebreaks(text)
    text.gsub("\n", "<br />")
  end

  def alphabet_links(models, url_method, current_letter, field=:name)
    ('A'..'Z').each do |letter|
      if current_letter == letter.downcase
        yield letter_nav("<span class='selected-letter'>#{letter}</span>")
      elsif models.any?{ |model| model.send(field).starts_with?(letter) }
        yield letter_nav(link_to(letter, self.send(url_method, :letter=> letter.downcase)))
      else
        yield letter_nav(letter)
      end
    end
    puts '<hr/>'
  end

  def letter_nav(content)
    "<span class='letter-nav'>#{content}</span>"
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

  def featured_speech(contribution)
    date = contribution.section.sitting.date.to_s(:long)
    link = section_contribution_link contribution, contribution.section
    type = contribution.sitting_type
    "#{date} #{link} #{type}"
  end
  
  def commons_membership_details(membership, display=:person)
    if display == :person
      text = link_to membership.person.name, person_url(membership.person)
    else
      text = link_to membership.constituency.name, constituency_url(membership.constituency)
    end
    text += " #{dates_or_unknown(membership)}"
  end
  
  def title_details(title, options={})
    text = nil
    if !title.name.blank?
      text = title.name 
    else
      text = "#{title.degree} #{title.title}"
    end
    if options[:include_dates] == true
      if title.start_date 
        if title.estimated_start_date
          text += " #{title.start_date.year} - "
        else
          text += " #{title.start_date.to_s(:long)} - "
        end
        if title.end_date
          if title.estimated_end_date
            text += title.end_date.year.to_s
          else
            text += title.end_date.to_s(:long)
          end
        end
      end
    end
    text
  end

  def office_holder_details holder, options
    if options[:link_to] == :office
      link = office_link(holder.office)
    elsif options[:link_to] == :person
      link = link_to holder.person.name, person_url(holder.person)
    end
    details = "#{link} #{dates_or_unknown(holder)}"
    details += "<sup>*</sup>" unless holder.confirmed?
    details
  end

  def office_link office
    link_to(office.name, office_url(:name => office.slug))
  end

  def dates_or_unknown(model)
    if model.respond_to?('estimated_start_date?') and model.estimated_start_date?
      text = model.start_date ? model.start_date.year.to_s : '?'
    else
      text =  model.start_date ? model.start_date.to_s(:long) : '?'
    end
    text += ' - '
    if model.respond_to?('estimated_end_date?') and model.estimated_end_date?
      text += model.end_date ? model.end_date.year.to_s : '?'
    else
      text += model.end_date ? model.end_date.to_s(:long) : '?'
    end
  end

  def total_count model_type
    "#{number_with_delimiter(model_type.count)} #{model_type.name.downcase.pluralize} in total"
  end

  def preview section
    preview = ''

    section.contributions.each do |contribution|
      preview += "#{contribution.member_name} #{contribution.text} "
      break if preview.size > 75
    end

    preview = strip_tags preview
    truncate(preview, 75)
  end

  def format_display_text text, sitting, options
    text = String.new text
    text.strip!
    text.sub!(/\A(<[^>]+>)?:\s*/, '\1')
    text = normalize_quote_tags(text)

    doc = Hpricot.XML(text.starts_with?('<division>') ? text : "<wrapper>#{text}</wrapper>")
    text_context = { :parts => [],
                     :sitting => sitting }
    final_text = handle_contribution_part doc.children.first, text_context, options
    final_text = final_text.join('').squeeze(' ')
    final_text.gsub!("&#x00B7;", ".")

    final_text = UrlResolver.new(final_text).markup_references
    final_text = EcDirectiveResolver.new(final_text).markup_references
    final_text
  end

  def normalize_quote_tags text
    text = text.gsub(':<quote>','<quote>')
    text = text.gsub('<quote>"','<quote>')
    text = text.gsub('"</quote>','</quote>')
    text
  end

  def column_marker(column, sitting)
    column_string = sitting.class.normalized_column(column)
    title = "Col. #{column_string}"
    anchor = "column_#{column_string.downcase}"
    title += " &mdash; #{sitting.hansard_reference column}" if sitting
    "<a class='permalink column-permalink' id='#{anchor}' title='#{title}' name='#{anchor}' href='##{anchor}' rel='bookmark'>#{column_string}</a>"
  end

  def image_marker(image, sitting)
    return "" unless image_exists?(image)
    url = image_url(image)
    "<a href='#{url}' class='page-preview'>P</a>"
  end
  
  def image_url(image)
    "/images/pages/#{image}.jpg"
  end
  
  def image_exists?(image)
    File.exist?("#{RAILS_ROOT}/public/images/pages/#{image}.jpg")
  end
  
  def contribution_permalink(contribution, marker_options)
    if marker_options[:hide_markers]
      ''
    else
      "<a class='permalink' href='##{contribution.anchor_id}' title='Link to this contribution' rel='bookmark'>&sect;</a>"
    end
  end
  
  def speech_permalink(contribution, marker_options)
    if marker_options[:hide_markers]
      ''
    else
      "<a class='speech-permalink permalink' href='##{contribution.anchor_id}' title='Link to this speech by #{contribution.person.name}' rel='bookmark'>&sect;</a>"
    end
  end

  def markup_official_report_references(contribution, text)
    hansard_resolver = ReportReferenceResolver.new(text)
    text = hansard_resolver.markup_references do |reference|
      begin
        params = hansard_resolver.reference_params(reference)
      rescue
        params = {}
      end
      if params.empty?
        reference
      else
        if ! params[:date]
          month = params.delete(:month)
          day = params.delete(:day)
          params[:date] = Date.new(contribution.year, month, day)
        end
        hansard_reference = HansardReference.new(params)
        if hansard_reference.find_sections.size == 1
          link_to reference, column_url(hansard_reference.column, hansard_reference.find_sections.first)
        else
          reference
        end
      end
    end
    text
  end

  def handle_contribution_part node, context, options={}
    parts = context[:parts]
    sitting = context[:sitting]
    replacement_tags = { 'quote'  => 'q',
                         'i'      => 'span class="italic"',
                         'b'      => 'span class="bold"',
                         'u'      => 'span class="underline"',
                         'member' => 'span class="member"',
                         'membercontribution' => 'span class="membercontribution"',
                         'memberconstituency' => 'span class="memberconstituency"',
                         'sub'    => 'sub',
                         'tr'     => 'tr',
                         'td'     => 'td',
                         'sup'    => 'sup'}
    node.children.each do |child|

      if child.text? && (text = child.to_s).size > 0
        parts << text
      end

      next unless child.elem?

      if replacement_tags.has_key? child.name
        wrap_with replacement_tags[child.name], child, context, options
        next
      end

      case child.name
        when 'col'
          unless options[:hide_markers]
            parts << '</table>' if options[:in_table]
            parts << column_marker(child.inner_html, sitting) 
            parts << '<table>' if options[:in_table]
          end
        when 'image'
          unless options[:hide_markers]
            parts << image_marker(child[:src], sitting)
          end
        when 'ob'
          parts << '<span class="obscured">'
          parts << '[...]'
          parts << '</span>'
        when 'lb'
          parts << '</p><p>'
        when 'ol', 'ul'
          list = child.to_s
          list.sub!("<#{child.name}", %Q|<#{child.name} class="hide_numbering"|) if list[/<li>\d+\. /]
          parts << list
        when 'table'
          wrap_with 'table', child, context, options.merge(:in_table=>true)
        when 'abbr'
          parts << child.to_s
        when 'p'
          tag = 'p'
          tag += " id=\"#{child.attributes['id']}\"" if child.attributes['id']
          wrap_with tag, child, context, options
        when 'a'
          parts << child
        else
          parts << "<! -- Unhandled element: #{child.name}. -->"
      end

    end
    parts
  end

  private

    def wrap_with element, node, context, options={}
      element_name = element.split(' ').first
      context[:parts] << "<#{element}>"
      handle_contribution_part(node, context, options)
      context[:parts] << "</#{element_name}>"
    end

end
