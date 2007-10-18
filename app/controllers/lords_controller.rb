class LordsController < ApplicationController

  caches_page :index
  before_filter :check_valid_date, :only => [:show, :show_source, :edit]

  def index
    @sittings_by_year = all_grouped_by_year
  end

  def edit
    @sittings = find_in_resolution(@date, @resolution)
    if !@sittings.empty?
      @sitting = @sittings.first
      @day = true
    end
  end

  def show
    @sittings = find_in_resolution(@date, @resolution)
    if @sittings.size > 1
      @sittings_by_year = [@sittings]
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
    @sitting = find_by_date(@date.to_s)
    data = @sitting.data_file.file.read
    respond_to do |format|
      format.xml { render :xml => data }
    end
  end

  protected

    def all_grouped_by_year
      HouseOfLordsSitting.all_grouped_by_year
    end

    def find_in_resolution date, resolution
      HouseOfLordsSitting.find_in_resolution(date, resolution)
    end

    def find_by_date date
      HouseOfCommonsSitting.find_by_date(date.to_s)
    end
end