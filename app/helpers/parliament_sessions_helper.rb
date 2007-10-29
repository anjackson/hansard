module ParliamentSessionsHelper

  def series_link series_number
    url_component = series_number.downcase+'-series'
    link_to series_number, url_for(:series_number_series => url_component, :controller => 'parliament_sessions', :action => 'series_index')
  end

  def volume_link parliament_session
    link_text = 'Volume ' + parliament_session.volume_in_series_to_i.to_s
    link_text += ' (Part ' + parliament_session.volume_in_series_part_number.to_s + ')' if parliament_session.volume_in_series_part_number
    link_to link_text, ''
  end
end
