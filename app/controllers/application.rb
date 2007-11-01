# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

class ApplicationController < ActionController::Base
  # helper :all # include all helpers, all the time
  include ExceptionNotifiable
  session :off

  def section_url(section)
    params = section.id_hash
    url_for(params.merge!(:controller => "sections", :action => "show"))
  end
  
  def self.is_production?
    RAILS_ENV == 'production'
  end

  def check_valid_date
    if params[:day]
      @resolution = :day
    elsif params[:month]
      @resolution = :month
    else
      @resolution = :year
    end

    case @resolution
      when :day;   @url_date = UrlDate.new(params)
      when :month; @url_date = UrlDate.new(params.merge(:day=>'01'))
      else         @url_date = UrlDate.new(params.merge(:month=>'jan',:day=>'01'))
    end

    redirect_date @url_date if not @url_date.is_valid_date?

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
