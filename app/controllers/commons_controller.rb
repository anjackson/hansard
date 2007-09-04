class CommonsController < ApplicationController
  
  caches_page :index, :show_commons_hansard
  before_filter :check_valid_date, :only => [:show_commons_hansard, :show_commons_hansard_source]

  def show_commons_hansard
    @day = true
    @sitting = HouseOfCommonsSitting.find_by_date(@date.to_date.to_s)
    @marker_options = {}
    respond_to do |format|
      format.html
      format.xml { render :xml => @sitting.to_xml }
    end
  end
  
  def show_commons_hansard_source
    @sitting = HouseOfCommonsSitting.find_by_date(@date.to_date.to_s)
    data = @sitting.data_file.file.read
    respond_to do |format|
      format.xml { render :xml => data }
    end
  end

  def index
    @sittings = HouseOfCommonsSitting.find(:all)
  end
  
  private 
  
  def check_valid_date 
    @date = UrlDate.new(params)
    if not @date.is_valid_date?
      render :text => 'not valid date' and return false
    end
  end
  
end