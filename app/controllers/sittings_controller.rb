class SittingsController < ApplicationController

  before_filter :check_valid_date
  after_filter :strip_images, :only => [:show]
  # caches_page needs come after any other after_filters
  caches_page :index, :show, :feed
  helper :sections


  def index
    @date = FIRST_DATE unless @date
    @sitting_type = model
    @timeline_resolution = Date.higher_resolution(@resolution)
    @title = "HANSARD 1803&ndash;2005" if params[:home_page]
    render :template => "sittings/index" and return
  end

  def show
    @sitting = true
    @sitting_type = model
    @sittings = model.find_in_resolution(@date, @resolution)
    @sittings = Sitting.sort_by_type(@sittings)
    @day = true
    @marker_options = {}

    respond_to do |format|
      format.html { render :template => "sittings/show" }
      format.xml { render :xml => @sittings.to_xml }
      format.opml { render_show_sittings_opml }
      format.js  { render :text => @sittings.to_json(:except => :date, :methods => :top_level_sections), :content_type => "text/x-json" }
    end
  end
  
  def feed
    @years = params[:years].to_i
    respond_with_404 and return false unless DEFAULT_FEEDS.include? @years
    @items = Sitting.sections_from_years_ago(@years, Date.today, 10)
    @items.each{ |item| render_feed_section(item) }
    respond_to do |format|
      format.xml do
        render :template => 'sittings/years_ago.atom.builder'
      end
    end
  end

  def render_show_sittings_opml
    render :template => "sittings/show.opml.haml"
  end

  private

    def model
      Sitting
    end

    def render_feed_section(item)
      @section = item.first
      @sitting = @section.sitting
      @marker_options = { :hide_markers => true }
      content = render_to_string :template => 'sections/show.haml'
      item << content
    end
end