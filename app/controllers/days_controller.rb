class DaysController < ApplicationController

  before_filter :check_valid_date, :only => [:show]
  
  def index
    @date = Sitting.most_recent.date
    get_calendar_data
    render :action => "show"
  end
  
  def show
    get_calendar_data
  end

  private
  
   def get_calendar_data
     @sittings = Sitting.find_all_present_on_date(@date)
     first, last = @date.first_and_last_of_month
     @dates_with_material = first.material_dates_upto(last)
   end
   
end