class PeopleController < ApplicationController

  caches_page :index, :show
  before_filter :check_letter_index, :only => [:index]

  def index
    @people = Person.find_all_sorted
    @list_people = @people.select{|person| person.ascii_alphabetical_name[/\A#{@letter}/i] }
  end

  def show
    @person = Person.find_by_slug(params[:name])
    no_model_response("person") and return false unless @person
    @year = params[:year].to_i if params[:year]
    respond_to do |format|
      format.html { }
      format.js { render :text => @person.to_json(Person.json_defaults), :content_type => "text/x-json" }
    end
  end
end