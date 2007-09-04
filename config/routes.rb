def def_route path, action, map
  map.method_missing action, path, :action => action.to_s
end

def def_index_route path, map
  map.method_missing path.to_sym, path, :action => 'index'
end

ActionController::Routing::Routes.draw do |map|

  map.home '', :controller => "commons", :action => "index"
  map.search 'search', :controller => 'search', :action => "index"

  year_patt = /(19|20)\d\d/
  month_patt = /(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|[01]?\d)/
  day_patt = /[0-3]?\d/

  date_format = { :year => year_patt,
                  :month => month_patt,
                  :day => day_patt }

  date_span_format = { :start_year => year_patt,
                       :start_month => month_patt,
                       :start_day => day_patt,
                       :end_year => year_patt,
                       :end_month => month_patt,
                       :end_day => day_patt }

  formatted_date_options = { :requirements => date_format }
  date_options = { :requirements => date_format, :month => nil, :day => nil }
  date_span_options = { :requirements => date_span_format }
  date = ':year/:month/:day'
  date_span = ':start_year/:start_month/:start_day/:end_year/:end_month/:end_day'

  map.with_options(:controller => 'indices') do |indices|

    indices.map 'indices', :action => 'index'

    indices.with_options(date_span_options) do |by_date_span|
      def_route "indices/#{date_span}", :show, by_date_span
    end

  end

  map.with_options(:controller => 'commons') do |commons|

    commons.with_options(formatted_date_options) do |by_date|
      def_route "commons/#{date}.:format", :show_commons_hansard, by_date
    end

    commons.with_options(date_options) do |by_date|
      def_route "commons/#{date}", :show_commons_hansard, by_date
    end

    commons.with_options(formatted_date_options) do |by_date|
      def_route "commons/source/#{date}.:format", :show_commons_hansard_source, by_date
    end

  end

  map.with_options(:controller => 'data_files') do |df|
    def_index_route "data_files", df
  end
end