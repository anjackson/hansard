class DivisionsController < ApplicationController

  caches_page :index
  before_filter :check_letter_index, :only => [:index]
  before_filter :check_valid_date, :only => [:show_division, :show_division_formatted, :redirect_to_division]
  # caches_page needs come after any other after_filters
  caches_page :index, :show_division, :show_division_formatted

  def index
    @divisions_in_groups_by_section_title_and_section_and_sub_section = Division.divisions_in_groups_by_section_title_and_section_and_sub_section(@letter)
    @letters = Division.letters
  end

  def show_division
    with_sitting_and_section(params[:type], @date, params[:id]) do |sitting, section|
      @division = section.find_division(params[:division_number])

      if @division
        respond_to do |format|
          format.html { @params_for_csv_url = params_for_csv_url(params) }
          format.csv { render :text => @division.to_csv(request.url) }
        end
      else
        respond_with_404
      end
    end
  end

  def show_division_formatted
    show_division
  end

  def params_for_csv_url params
    csv_params = params.merge({:format=>'csv',:action=>'show_division_formatted'})
    csv_params
  end

end
