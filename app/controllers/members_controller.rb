class MembersController < ApplicationController

  caches_page :index, :show_member

  def index
    @members = find_all_members
  end

  def show_member
    @member = find_member params[:name]
    @contributions_in_groups_by_year_and_section = @member.contributions_in_groups_by_year_and_section
  end

  protected

    def find_all_members
      Member.find_all_members
    end

    def find_member slug
      Member.find_member slug
    end
end
