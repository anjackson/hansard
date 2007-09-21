class SectionsController < ApplicationController
  
  before_filter :check_valid_date, :only => [:show]
  
  def show
    @marker_options = {}
    @sitting = HouseOfCommonsSitting.find_by_date(@date.to_date.to_s)
    @section = @sitting.sections.find_by_slug(params[:id])
  end

end