class WrittenAnswersController < ApplicationController

  before_filter :check_valid_date, :only => [:show, :show_source]
  
  def index
    @sittings = WrittenAnswersSitting.find(:all, :order => "date asc")
  end
  
  def show
    @day = true
    @sitting = WrittenAnswersSitting.find_by_date(@date.to_s)
    @marker_options = {}
    respond_to do |format|
      format.html
      format.xml { render :xml => @sitting.to_xml }         
    end
  end
  
  def show_source
    @sitting = WrittenAnswersSitting.find_by_date(@date.to_s)
    data = @sitting.data_file.file.read
    respond_to do |format|
      format.xml { render :xml => data }
    end
  end
  
end