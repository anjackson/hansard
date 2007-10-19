class MembersController < ApplicationController

  def index
    sql = %Q[select distinct member, count(member) AS count_by_member from contributions where type = 'MemberContribution' group by member;]
    @contributions = MemberContribution.find_by_sql(sql)
    @member_to_frequency = @contributions.collect {|c| [c.member, c.count_by_member] }
  end
end
