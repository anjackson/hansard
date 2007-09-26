class SectionsController < ApplicationController
  
  before_filter :check_valid_date, :only => [:show]
  
  def show
    @marker_options = {}
    types_to_sittings = { "commons"        => HouseOfCommonsSitting,
                          "writtenanswers" => WrittenAnswersSitting }
    @sitting = types_to_sittings[params[:type]].find_by_date(@date.to_date.to_s)
    @section = @sitting.sections.find_by_slug(params[:id])
  end

end