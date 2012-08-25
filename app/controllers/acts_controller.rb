class ActsController < ApplicationController

  caches_page :index, :show
  before_filter :check_letter_index, :only => [:index]

  def index
    @acts = Act.find_all_sorted
    @list_acts = @acts.select{|act| act.name[/\A#{@letter}/i] }
  end

  def show
    @act = Act.find_by_slug(params[:name])
    no_model_response "act" and return false unless @act
    @other_acts = @act.others_by_name
  end

end