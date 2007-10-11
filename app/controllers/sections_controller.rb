class SectionsController < ApplicationController

  before_filter :check_valid_date, :only => [:show]

  def show
    sitting_model = Sitting.uri_component_to_sitting_model(params[:type])

    @sitting = sitting_model.find_by_date(@date.to_date.to_s)
    @section = @sitting.sections.find_by_slug(params[:id])
    @marker_options = {}
  end

end