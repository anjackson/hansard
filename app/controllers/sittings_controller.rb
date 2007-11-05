class SittingsController < ApplicationController

  caches_page :index
  before_filter :check_valid_date, :only => [:show, :show_source]
  
  def index
    @date = LAST_DATE
    @sittings_by_year = model.all_grouped_by_year
    @timeline_resolution = lower_resolution(@resolution)
  end

  def show
    @sittings = model.find_in_resolution(@date, @resolution)
    if @sittings.size > 1
      @sittings_by_year = [@sittings]
      @timeline_resolution = lower_resolution(@resolution)
      render :action => "index" and return false
    end
    @marker_options = {}
    if !@sittings.empty?
     @sitting = @sittings.first
     @day = true
    end
    respond_to do |format|
     format.html
     format.xml { render :xml => @sitting.to_xml }
    end
  end

  def show_source
    @sitting = model.find_by_date(@date.to_s)
    data = @sitting.data_file.file.read
    respond_to do |format|
     format.xml { render :xml => data }
    end
  end

  private

    def model
      Sitting
    end
    
    def lower_resolution(resolution)
      case resolution
      when nil
        :century
      when :century
        :decade
      when :decade
        nil
      when :year
        :month
      when :month
        :day
      end
    end

end