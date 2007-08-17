def def_route path, action, map
  map.method_missing action, path, :action => action.to_s
end

def def_index_route path, map
  map.method_missing path.to_sym, path, :action => 'index'
end

ActionController::Routing::Routes.draw do |map|
  
  map.sitting "sittings/:id.:format", :controller => 'sittings', :action => 'show'
  map.sitting "sittings/:id", :controller => 'sittings', :action => 'show'

  date_format = { :year => /(19|20)\d\d/,
                  :month => /(jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec|[01]?\d)/,
                  :day => /[0-3]?\d/ }

  date_options = { :requirements => date_format, :month => nil, :day => nil }
  date = ':year/:month/:day'

  map.with_options(:controller => 'commons') do |commons|
    commons.with_options(date_options) do |by_date|
      def_route "commons/#{date}", :show_commons_hansard, by_date
    end
  end
  
  map.oral_question "oral_questions/:id.:format", :controller => 'oral_question_sections', :action => 'show'
  map.oral_question "oral_questions/:id", :controller => 'oral_question_sections', :action => 'show'
 
end