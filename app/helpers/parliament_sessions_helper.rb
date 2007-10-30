module ParliamentSessionsHelper

  def volume_in_series_title series_number
    "Volumes in #{series_number.titleize} Series, by number"
  end

  def reign_title monarch_name
    parts = []
    monarch_name.each('_') do |part|
      if part.is_roman_numeral?
        parts << part.upcase
      else
        parts << part.titleize
      end
    end
    name = parts.join(' ').squeeze(' ')
    "Sessions by Years of the Reign of #{name}"
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
    url_component = monarch_name.downcase.gsub(' ','_')
    link_to name, url_for(:monarch_name => url_component, :controller => 'parliament_sessions', :action => 'monarch_index')
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
    text = reign_link_text(parliament_session.year_of_the_reign)
    link_to text, ''
  end

  def reign_link_text year_of_the_reign
    text = year_of_the_reign.capitalize
    if year_of_the_reign.include?('-')
      text.gsub!(' ','-')
      text += ' year of the reign'
    elsif (year_of_the_reign.include?('&amp;') ||
          year_of_the_reign.include?('&#x0026;') ||
          year_of_the_reign.upcase.include?('AND'))
      text += ' years of the reign'
    else
      text += ' year of the reign'
    end
    text
  end

  def column_links parliament_session
    first = parliament_session.start_column.to_i
    last = parliament_session.end_column.to_i
    columns = []

    sittings = parliament_session.sittings

    first.upto(last) do |column|
      the_section = nil
      sittings.each do |sitting|
        unless the_section
          the_section = sitting.find_section_by_column(column)
        end
      end
      columns << column_link(column, the_section)
    end

    columns.join(', ')
  end

  def column_link column, section=nil
    if section
      link_to column, "#{section_url(section)}#column_#{column}"
    else
      column.to_s
    end
  end
end
