class SittingsController < ApplicationController
  before_filter :authorize
  
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @sitting_pages, @sittings = paginate :sittings, :per_page => 10, :order => "Id DESC"
  end

  def show
    @sitting = Sitting.find(params[:id])
    @sections = @sitting.sections
    @turns = @sitting.turns
    
  end

end
