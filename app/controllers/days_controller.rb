class DaysController < ApplicationController

  def index
    @sitting = Sitting.most_recent
  end
  
  def show
    url_date = UrlDate.new(params)
    if not url_date.is_valid_date?
      redirect_date url_date
    else
      @date = url_date.to_date
      @sittings = Sitting.find_all_present_on_date(@date)
    end
  end

  private
  
   def redirect_date date
     params[:day] = date.day
     params[:month] = date.month
     headers["Status"] = "301 Moved Permanently"
     redirect_to params
   end
   
end