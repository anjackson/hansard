module ParliamentSessionsHelper

  def series_link series_number
    url_component = series_number.downcase+'-series'
    link_to series_number, url_for(:series_number_series => url_component, :controller => 'parliament_sessions', :action => 'series_index')
  end

  def volume_link parliament_session
    # session = parliament_session
    if parliament_session.volume_in_series.is_roman_numerial?
      link_text = "Volume #{parliament_session.volume_in_series} (#{parliament_session.volume_in_series_to_i.to_s})"
    else
      link_text = "Volume #{parliament_session.volume_in_series_to_i.to_s}"
    end
    link_text += " (Part #{parliament_session.volume_in_series_part_number.to_s})" if parliament_session.volume_in_series_part_number
    link_text += ", #{parliament_session.house}"
    link_to link_text, ''
  end
end
