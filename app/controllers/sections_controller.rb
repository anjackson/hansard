class SectionsController < ApplicationController

  before_filter :check_valid_date, :only => [:show]
  after_filter :strip_images, :only => [:show]
  # caches_page needs come after any other after_filters
  caches_page :show

  def show
    identifier = params[:id]

    if identifier[/^division_\d+$/]
      redirect_to_division identifier
    else
      show_section identifier
    end
  end

  def redirect_to_division division_number
    with_sitting(params[:type], @date) do |sitting|
      redirect_to_division_if_found sitting, division_number
    end
  end

  protected

    def redirect_to_division_if_found sitting, division_number
      if division = sitting.find_division(division_number)
        section_id = division.section.slug
        url_params = @url_date.to_hash.merge({ :controller => 'divisions', :id => section_id, :action => 'show_division', :division_number => division_number })
        url = url_for url_params
        redirect_to url, :status => :moved_permanently
      else
        url_params = { :controller => params[:type], :action => 'show' }
        url = url_for url_params.merge( @url_date.to_hash )
        redirect_to url, :status => :see_other
      end
    end

    def show_section section_slug
      with_sitting_and_section(params[:type], @date, section_slug) do |sitting, section|
        @sitting, @section = sitting, section
        @marker_options = {}

        respond_to do |format|
          format.html{}
          format.js  { render :text => @section.to_json, :content_type => "text/x-json" }
        end
      end
    end
end