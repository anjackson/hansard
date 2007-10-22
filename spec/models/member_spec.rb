require File.dirname(__FILE__) + '/../spec_helper'

describe Member, 'find_member' do
  before do
    @name = 'mr_boyes'
    @member = mock(Member)
    @member.stub!(:slug).and_return(@name)
    MemberContribution.stub!(:find_all_members).and_return([@member])
  end

  it 'should find member based on slug "mr_boyes"' do
    Member.find_member(@name).should == @member
  end

  it 'should find all members' do
    Member.find_all_members.should == [@member]
  end
end

describe Member, 'with contributions' do
  before do
    @one = Contribution.new
    @two = Contribution.new
    @three = Contribution.new
    @one.stub!(:date).and_return(Date.new(1999,1,1))
    @two.stub!(:date).and_return(Date.new(1999,12,31))
    @three.stub!(:date).and_return(Date.new(2000,1,1))

    contributions = [@two, @three, @one]
    @member = Member.new('Mr Boyes', contributions.size)
    @member.stub!(:contributions).and_return(contributions)
  end

  it 'should return contributions grouped by year, ascending' do
    groups = @member.contributions_in_groups_by_year
    groups.size.should == 2
    groups[0].size.should == 2
    groups[1].size.should == 1
    groups.should == [[@one, @two], [@three]]
  end
end
