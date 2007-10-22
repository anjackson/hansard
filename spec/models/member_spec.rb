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
