module ParliamentSessionsHelper

  def volume_in_series_title series_number
    "Volumes in #{series_number.titleize} Series, by number"
  end

  def format_monarch_name monarch_name
    parts = []
    monarch_name.each('_') do |part|
      if part.is_roman_numeral?
        parts << part.upcase
      else
        parts << part.titleize
      end
    end
    name = parts.join(' ').squeeze(' ')
    name
  end

  def monarch_link monarch_name
    parts = []
    monarch_name.each(' ') do |part|
      if part.is_roman_numeral?
        parts << part
      else
        parts << part.titleize
      end
    end
    name = parts.join(' ').squeeze(' ')
    url_component = monarch_url_component(monarch_name)
    url = url_for(:monarch_name => url_component, :controller => 'parliament_sessions', :action => 'monarch_index')
    link_to name, url
  end

  def monarch_url_component monarch_name
    monarch_name.downcase.gsub(' ','_')
  end

  def series_link series_number
    link_text = "#{series_number.titleize} Series"
    url_component = series_number.downcase
    link_to link_text, url_for(:series_number => url_component, :controller => 'parliament_sessions', :action => 'series_index')
  end

  def volume_link parliament_session
    link_text = volume_link_text parliament_session
    series = parliament_session.series_number.downcase
    volume = parliament_session.volume_in_series_number.to_s

    url = url_for(:series_number => series, :volume_number => volume, :action => 'volume_index', :controller => 'parliament_sessions')
    if parliament_session.volume_in_series_part_number
      url += "_#{parliament_session.volume_in_series_part_number.to_s}"
    end
    link_to link_text, url
  end

  def volume_link_text parliament_session
    if parliament_session.volume_in_series.is_roman_numeral?
      link_text = "Volume #{parliament_session.volume_in_series} (#{parliament_session.volume_in_series_number.to_s})"
    else
      link_text = "Volume #{parliament_session.volume_in_series_number.to_s}"
    end
    link_text += " (Part #{parliament_session.volume_in_series_part_number.to_s})" if parliament_session.volume_in_series_part_number
    link_text += ", #{parliament_session.house}"

    unless parliament_session.comprising_period.blank?
      period = parliament_session.comprising_period.titleize.gsub(' To',' to').gsub('&#X2014;','&#x2014;')
      link_text += ", #{period}"
    end
    link_text
  end

  def reign_link parliament_session
    text = "#{reign_link_text(parliament_session.regnal_years)}, #{parliament_session.house}"
    url_component = monarch_url_component(parliament_session.monarch_name)
    years = parliament_session.regnal_years.downcase.gsub(' ','').sub('and', '_and_').sub('&amp;', '_and_').sub('&#x0026;','_and_')
    url = url_for(:monarch_name => url_component, :regnal_years => years, :controller => 'parliament_sessions', :action => 'regnal_years_index')
    link_to text, url
  end

  def reign_link_text regnal_years
    text = regnal_years.capitalize

    if regnal_years.include?('-')
      text.gsub!(' ','-')
      text += ' year of the reign'
    elsif (regnal_years.include?('&amp;') ||
          regnal_years.include?('&#x0026;') ||
          regnal_years.upcase.include?('AND'))
      text += ' years of the reign'
    else
      text += ' year of the reign'
    end

    while (match = /(\d+ )/.match text)
      number = match[1]
      text = text.sub(number, number_to_ordinal(number)+' ')
    end

    text
  end

  def sitting_column_links sitting
    first = sitting.start_column.to_i
    last = sitting.end_column.to_i
    columns = []

    place_holder_blank = ''
    (first % 10).times {|i| columns << place_holder_blank}
    first.upto(last) do |column|
      the_section = sitting.find_section_by_column(column)
      columns << column_link(column, the_section)
    end

    rows = []
    columns.in_groups_of(10) {|g| rows << '<tr><td class="column_number">' + g.join('</td><td class="column_number">') + '<tr><td>' }

    '<table><tbody>' + rows.join('') + '</tbody></table>'
  end

  def column_link column, section
    if section
      link_to column, "#{section_url(section)}#column_#{column}"
    else
      column.to_s
    end
  end

  def number_to_ordinal(number)
    number = number.to_i
    if (10...20) === number
      "#{number}th"
    else
      suffixes = %w{ th st nd rd th th th th th th }
      value = number.to_s
      last = value[-1..-1].to_i
      value + suffixes[last]
    end
  end
end
