# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  before_filter :authorize
  # Pick a unique cookie name to distinguish our session data from others'
  session :session_key => '_hansard_session_id'
  
  def authorize
    unless logged_in?
      @session["return_to"] = @request.request_uri
      redirect_to( :controller => 'login', :action => 'login' )
      return false
    end
  end

  def logged_in?
    session[:username] != nil
  end
  
end
