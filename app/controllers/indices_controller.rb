class IndicesController < ApplicationController

  def show
    start_date = UrlDate.new(:year => params[:start_year], 
                             :month => params[:start_month],
                             :day => params[:start_day])
    end_date = UrlDate.new(:year => params[:end_year], 
                           :month => params[:end_month],
                           :day => params[:end_day])
                           
    if (not start_date.is_valid_date?) or (not end_date.is_valid_date?)
      render :text => 'not valid date'
    else
      @letter = params[:letter] || "A"
      @index = Index.find_by_date_span(start_date.to_date.to_s, end_date.to_date.to_s)
    end
  end
  
  def index
    @indices = Index.find(:all)
  end
  
end