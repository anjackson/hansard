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

  with_controller :indices, map do |indices|
    make_index_route 'indices', indices

    indices.with_options(date_span_options) do |by_date_span|
      make_route "indices/#{date_span}", :show, by_date_span
    end
  end

  with_controller :days, map do |days|
    days.with_options(date_options) do |by_date|
      make_route "#{date}", :show, by_date
    end
  end

  with_controller :lords, map do |lords|
    make_index_route 'lords', lords

    lords.with_options(formatted_date_options) do |by_date|
      make_route "lords/#{date}.:format", :show, by_date
      make_route "lords/source/#{date}.:format", :show_source, by_date
    end

    lords.with_options(date_options) do |by_date|
      make_route "lords/#{date}", :show, by_date
    end
  end

  with_controller :commons, map do |commons|
    make_index_route 'commons', commons

    commons.with_options(formatted_date_options) do |by_date|
      make_route "commons/#{date}.:format", :show, by_date
      make_route "commons/source/#{date}.:format", :show_source, by_date
    end

    commons.with_options(date_options) do |by_date|
      make_route "commons/#{date}", :show, by_date
    end
  end

  with_controller :written_answers, map do |written|
    make_index_route 'written_answers', written

    written.with_options(formatted_date_options) do |by_date|
      make_route "written_answers/#{date}.:format", :show, by_date
      make_route "written_answers/source/#{date}.:format", :show_source, by_date
    end

    written.with_options(date_options) do |by_date|
      make_route "written_answers/#{date}", :show, by_date
    end
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

  with_controller :sections, map do |sections|
    sections.with_options(formatted_date_options) do |by_date|
      make_route ":type/#{date}/:id", :show, by_date
      make_route ":type/#{date}/:id/nest", :nest, by_date
      make_route ":type/#{date}/:id/unnest", :unnest, by_date
    end
  end

end