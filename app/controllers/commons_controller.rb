class CommonsController < ApplicationController
  
  caches_page :show
  before_filter :check_valid_date, :only => [:show, :show_source]

  def show
    @day = true
    @sitting = HouseOfCommonsSitting.find_by_date(@date.to_date.to_s)
    @marker_options = {}
    respond_to do |format|
      format.html
      format.xml { render :xml => @sitting.to_xml }
    end
  end
  
  def show_source
    @sitting = HouseOfCommonsSitting.find_by_date(@date.to_date.to_s)
    data = @sitting.data_file.file.read
    respond_to do |format|
      format.xml { render :xml => data }
    end
  end

  def index
    @sittings = HouseOfCommonsSitting.find(:all, :order => "date asc")
  end
  

end