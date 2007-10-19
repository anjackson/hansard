class MembersController < ApplicationController

  def index
    @members = MemberContribution.find_all_members
  end
end
