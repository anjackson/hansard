class MembersController < ApplicationController

  def index
    @members = find_all_members
  end

  def show_member
    @member = find_member params[:name]
  end

  protected

    def find_all_members
      Member.find_all_members
    end

    def find_member slug
      Member.find_member slug
    end
end
