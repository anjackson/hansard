def make_route path, action, map
  map.method_missing action, path, :action => action.to_s
end

def make_index_route path, map
  map.method_missing path.to_sym, path, :action => 'index'
end

def with_controller name, map
  map.with_options(:controller => name.to_s) do |sub_map|
    yield sub_map
  end
end

ActionController::Routing::Routes.draw do |map|
  
  with_controller :sittings, map do |sittings|
    sittings.home '', :action => "index"
  end

  with_controller :search, map do |search|
    # search.home '', :action => "index"
    search.search 'search', :action => "show"
    search.random 'random', :action => "random"
  end

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

  with_controller :parliament_sessions, map do |parliament_session|
    make_index_route 'parliament_sessions', parliament_session
    make_route 'parliament_sessions/series/:series_number', :series_index, parliament_session
    make_route 'parliament_sessions/series/:series_number/volume/:volume_number', :volume_index, parliament_session
    make_route 'parliament_sessions/monarch/:monarch_name', :monarch_index, parliament_session
    make_route 'parliament_sessions/monarch/:monarch_name/regnal_years/:regnal_years', :regnal_years_index, parliament_session
  end

  with_controller :indices, map do |indices|
    make_index_route 'indices', indices

    indices.with_options(date_span_options) do |by_date_span|
      make_route "indices/#{date_span}", :show, by_date_span
    end
  end

  %w[sittings lords commons written_answers lords_reports].each do |controller_name|
    with_controller controller_name.to_sym, map do |controller|
       make_index_route controller_name, controller

       controller.with_options(formatted_date_options) do |by_date|
         make_route "#{controller_name}/#{date}.:format", :show, by_date
         make_route "#{controller_name}/source/#{date}.:format", :show_source, by_date
       end

       controller.with_options(date_options) do |by_date|
         make_route "#{controller_name}/#{date}", :show, by_date
       end
     end
  end

  with_controller :members, map do |member|
    make_index_route 'members', member
    make_route "members/:name", :show_member, member
  end

  with_controller :data_files, map do |data_file|
    make_index_route "data_files", data_file
    make_route "data_files/warnings", :show_warnings, data_file
    make_route "data_files/reload_commmons_for_date/:date", :reload_commmons_for_date, data_file
    make_route "data_files/reload_lords_for_date/:date", :reload_lords_for_date, data_file
  end

  with_controller :source_files, map do |file|
    make_index_route "source_files", file
    file.source_file "source_files/:name", :action => "show"
  end

  with_controller :sections, map do |section|

    section.with_options(formatted_date_options) do |by_date|
      make_route ":type/#{date}/:id", :show, by_date
    end
  end

end