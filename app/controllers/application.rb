# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  include ExceptionNotifiable 
  
  def check_valid_date 
    @date = UrlDate.new(params)
    if not @date.is_valid_date?
      render :text => 'not valid date' and return false
    end
  end
  
end
