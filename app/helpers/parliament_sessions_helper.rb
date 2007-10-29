module ParliamentSessionsHelper

  def volume_in_series_title series_number
    "Volumes in #{series_number.titleize}, by number"
  end

  def monarch_link monarch_name
    parts = []
    monarch_name.each(' ') do |part|
      if part.is_roman_numerial?
        parts << part
      else
        parts << part.titleize
      end
    end
    name = parts.join(' ').squeeze(' ')
    link_to name, ''
  end

  def series_link series_number
    url_component = series_number.downcase+'-series'
    series = "#{series_number.titleize} Series"
    link_to series, url_for(:series_number_series => url_component, :controller => 'parliament_sessions', :action => 'series_index')
  end

  def volume_link parliament_session
    if parliament_session.volume_in_series.is_roman_numerial?
      link_text = "Volume #{parliament_session.volume_in_series} (#{parliament_session.volume_in_series_to_i.to_s})"
    else
      link_text = "Volume #{parliament_session.volume_in_series_to_i.to_s}"
    end
    link_text += " (Part #{parliament_session.volume_in_series_part_number.to_s})" if parliament_session.volume_in_series_part_number
    link_text += ", #{parliament_session.house}"

    unless parliament_session.comprising_period.blank?
      period = parliament_session.comprising_period.titleize.gsub(' To',' to').gsub('&#X2014;','&#x2014;')
      link_text += ", #{period}"
    end
    link_to link_text, ''
  end

end
