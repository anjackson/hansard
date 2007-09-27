# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  helper :all # include all helpers, all the time
  include ExceptionNotifiable 
  
  def check_valid_date 
    @url_date = UrlDate.new(params)
    if not @url_date.is_valid_date?
      redirect_date @url_date
    end
    begin
      @date = @url_date.to_date
    rescue
      redirect_to :action => "index"
    end
  end
  
  def redirect_date date
    params[:day] = date.day
    params[:month] = date.month
    headers["Status"] = "301 Moved Permanently"
    redirect_to params and return false
  end
  
end
