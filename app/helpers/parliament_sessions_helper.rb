module ParliamentSessionsHelper

  def series_link series_number
    url_component = series_number.downcase+'-series'
    link_to series_number, url_for(:series_number_series => url_component, :controller => 'parliament_sessions', :action => 'series_index')
  end
end
