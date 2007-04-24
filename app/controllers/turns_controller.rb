class TurnsController < ApplicationController
  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def list
    @turn_pages, @turns = paginate :turns, :per_page => 10
  end

  def show
    @turn = Turn.find(params[:id])
  end

  def new
    @turn = Turn.new
  end

  def create
    @turn = Turn.new(params[:turn])
    if @turn.save
      flash[:notice] = 'Turn was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @turn = Turn.find(params[:id])
  end

  def update
    @turn = Turn.find(params[:id])
    if @turn.update_attributes(params[:turn])
      flash[:notice] = 'Turn was successfully updated.'
      redirect_to :action => 'show', :id => @turn
    else
      render :action => 'edit'
    end
  end

  def destroy
    Turn.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
