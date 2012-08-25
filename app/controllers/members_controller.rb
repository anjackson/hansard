class MembersController < ApplicationController

  before_filter :check_letter_index, :only => [:index]

  def index
    redirect_to people_url, :status => :moved_permanently
  end

  def show
    redirect_to person_url(params[:name]), :status => :moved_permanently
  end
  
end
