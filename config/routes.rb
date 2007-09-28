def def_route path, action, map
  map.method_missing action, path, :action => action.to_s
end

def def_index_route path, map
  map.method_missing path.to_sym, path, :action => 'index'
end

ActionController::Routing::Routes.draw do |map|

  map.home '', :controller => "days", :action => "index"
  map.search 'search', :controller => 'search', :action => "index"

  year_patt = /(18|19|20)\d\d/
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

  map.with_options(:controller => 'indices') do |indexes|

    indexes.indices 'indices', :action => 'index'

    indexes.with_options(date_span_options) do |by_date_span|
      def_route "indices/#{date_span}", :show, by_date_span
    end

  end

  map.with_options(:controller => 'days') do |days|
    
    days.with_options(date_options) do |by_date|
      def_route "#{date}", :show, by_date
    end
    
  end
  
  map.with_options(:controller => 'commons') do |commons|

    commons.commons 'commons', :action => 'index'

    commons.with_options(formatted_date_options) do |by_date|
      def_route "commons/#{date}.:format", :show, by_date
    end

    commons.with_options(date_options) do |by_date|
      def_route "commons/#{date}", :show, by_date
    end

    commons.with_options(formatted_date_options) do |by_date|
      def_route "commons/source/#{date}.:format", :show_source, by_date
    end

  end

  map.with_options(:controller => 'written_answers') do |written|

    written.written_answers 'writtenanswers', :action => 'index'

    written.with_options(formatted_date_options) do |by_date|
      def_route "writtenanswers/#{date}.:format", :show, by_date
    end

    written.with_options(date_options) do |by_date|
      def_route "writtenanswers/#{date}", :show, by_date
    end

    written.with_options(formatted_date_options) do |by_date|
      def_route "writtenanswers/source/#{date}.:format", :show_source, by_date
    end

  end

  map.with_options(:controller => 'data_files') do |data_file|
    def_index_route "data_files", data_file
    def_route "data_files/warnings", :show_warnings, data_file
    def_route "data_files/reload_commmons_for_date/:date", :reload_commmons_for_date, data_file
  end

  map.with_options(:controller => 'source_files') do |file|
    file.source_files "source_files", :action => "index"
    file.source_file "source_files/:name", :action => "show"
  end

  map.with_options(:controller => 'sections') do |sections|
    sections.with_options(date_options) do |by_date|
      def_route ":type/#{date}/:id", :show, by_date
    end
  end

end