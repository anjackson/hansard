class SittingsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @sitting_pages, @sittings = paginate :sittings, :per_page => 10
  end

  def show
    @sitting = Sitting.find(params[:id])
  end

  def new
    @sitting = Sitting.new
  end

  def create
    @sitting = Sitting.new(params[:sitting])
    if @sitting.save
      flash[:notice] = 'Sitting was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @sitting = Sitting.find(params[:id])
  end

  def update
    @sitting = Sitting.find(params[:id])
    if @sitting.update_attributes(params[:sitting])
      flash[:notice] = 'Sitting was successfully updated.'
      redirect_to :action => 'show', :id => @sitting
    else
      render :action => 'edit'
    end
  end

  def destroy
    Sitting.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
