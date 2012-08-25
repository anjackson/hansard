class ConstituenciesController < ApplicationController

  caches_page :index, :show
  before_filter :check_letter_index, :only => [:index]

  def index
    @constituencies = Constituency.find_all_sorted
    @list_constituencies = @constituencies.select {|c| c.name[/\A#{@letter}/i] }
  end

  def show
    @constituency = Constituency.find_constituency(params[:name])
    no_model_response "constituency" and return unless @constituency
    respond_to do |format|
      format.html { }
      format.js { render :text => @constituency.to_json, :content_type => "text/x-json" }
    end
  end

end