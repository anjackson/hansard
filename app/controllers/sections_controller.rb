class SectionsController < ApplicationController

  in_place_edit_for :section, :title

  before_filter :check_valid_date, :only => [:show, :nest, :unnest]

  def show
    @sitting, @section = find_sitting_and_section(params[:type], @date, params[:id])
    @marker_options = {}
    @title = @section.plain_title
  end

  def nest
    if request.post?
      handle_nesting_change :nest!
    end
  end

  def unnest
    if request.post?
      handle_nesting_change :unnest!
    end
  end

  protected
    def find_sitting_and_section type, date, slug
      return Sitting.find_sitting_and_section(type, date, slug)
    end

    def handle_nesting_change nest_or_unnest
      sitting, section = find_sitting_and_section(params[:type], @date, params[:id])
      section.send(nest_or_unnest)
      params.delete(:action)
      slug = section.slug
      if section.parent_section_id
        section_id = '#section_'+section.parent_section_id.to_s
      else
        section_id = '#section_'+section.id.to_s
      end
      part = nest_or_unnest.to_s.chomp('!')
      redirect_to request.request_uri.sub('/'+part,'/edit').sub('/'+slug,'') + section_id
    end
end