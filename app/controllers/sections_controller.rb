class SectionsController < ApplicationController

  before_filter :check_valid_date, :only => [:show]

  def show
    sitting_model = types_to_sittings(params[:type])

    @sitting = sitting_model.find_by_date(@date.to_date.to_s)
    @section = @sitting.sections.find_by_slug(params[:id])
    @marker_options = {}
  end

  private

    def types_to_sittings type
      case type
        when "commons"
          HouseOfCommonsSitting
        when "lords"
          HouseOfLordsSitting
        when "writtenanswers"
          WrittenAnswersSitting
      end
    end

end