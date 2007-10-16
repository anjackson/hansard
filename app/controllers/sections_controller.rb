class SectionsController < ApplicationController

  before_filter :check_valid_date, :only => [:show, :nest, :unnest]

  def show
    @sitting, @section = find_sitting_and_section params[:type], @date, params[:id]
    @marker_options = {}
    @title = @section.title
  end

  def nest
    if request.post?
      @sitting, @section = find_sitting_and_section params[:type], @date, params[:id]
      @section.nest!
      params.delete(:action)
      redirect_to request.request_uri.sub('/nest','').sub('/'+@section.slug,'')+'#section_'+@section.id.to_s
    end
  end

  def unnest
    if request.post?
      @sitting, @section = find_sitting_and_section params[:type], @date, params[:id]
      @section.unnest!
      params.delete(:action)
      redirect_to request.request_uri.sub('/unnest','').sub('/'+@section.slug,'')+'#section_'+@section.id.to_s
    end
  end

  private
    def find_sitting_and_section type, date, slug
      sitting_model = Sitting.uri_component_to_sitting_model(type)
      sitting = sitting_model.find_by_date(date.to_date.to_s)
      section = sitting.sections.find_by_slug(slug)
      return sitting, section
    end
end