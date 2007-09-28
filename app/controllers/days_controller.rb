class DaysController < ApplicationController

  before_filter :check_valid_date, :only => [:show]
  
  def index
    @date = Sitting.most_recent.date
    get_calendar_data(@date, :day)
    render :action => "show"
  end
  
  def show
    get_calendar_data(@date, @resolution)
  end

  private
  
   def get_calendar_data(date, resolution)
     first, last = @date.first_and_last_of_month
     @sittings = Sitting.find_in_resolution(date, resolution)
     @dates_with_material = first.material_dates_upto(last)
   end
   
end