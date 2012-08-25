class OfficesController < ApplicationController

  caches_page :index, :show
  before_filter :check_letter_index, :only => [:index]

  def index
    @offices = Office.find_all_sorted
    @list_offices = @offices.select{|office| office.name[/\A#{@letter}/i] }
  end

  def show
    @office = Office.find_office(params[:name])
    no_model_response "office" and return false unless @office
  end

end