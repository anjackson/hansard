class MembersController < ApplicationController

  caches_page :index
  
  def index
    @members = find_all_members
  end

  def show_member
    @member = find_member params[:name]
    @contributions_in_groups_by_year = @member.contributions_in_groups_by_year
  end

  protected

    def find_all_members
      Member.find_all_members
    end

    def find_member slug
      Member.find_member slug
    end
end
