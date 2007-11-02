require File.dirname(__FILE__) + '/../spec_helper'

describe Member, 'on creation' do
  it 'should populate slug from name' do
    Member.delete_all
    name = 'Mr Tickled'
    member = Member.new
    member.name = name
    member.save!
    member.slug.should == 'mr-tickled'
    Member.delete_all
  end
end

describe Member, 'find_or_create_from_name' do
  it 'should return existing member matching the supplied name if there is one' do
    Member.delete_all
    existing_member = mock_model(Member)
    Member.should_receive(:find_by_name).and_return(existing_member)
    name = 'Mr Tickle'
    member = Member.find_or_create_from_name(name)
    member.should == existing_member
    Member.delete_all
  end

  it 'should create new member if no member matching the supplied name' do
    Member.delete_all
    Member.should_receive(:find_by_name).and_return(nil)

    name = 'Mr Tickle'
    member = Member.find_or_create_from_name(name)
    member.should_not be_nil
    member.should be_an_instance_of(Member)
    member.name.should == name
    member.slug.should == 'mr-tickle'
    Member.delete_all
  end
end

describe Member, 'find_member' do
  before do
    @slug = 'mr_boyes'
    @member = mock(Member)
    @member.stub!(:name).and_return('Mr Boyes')
    @member.stub!(:slug).and_return(@slug)
  end

  it 'should find member based on slug "mr_boyes"' do
    Member.stub!(:find_by_slug).and_return(@member)
    Member.find_member(@slug).should == @member
  end

  it 'should find all members' do
    Member.stub!(:find).and_return([@member])
    Member.find_all_members.should == [@member]
  end
end

describe Member, 'with contributions' do
  before do
    @one = Contribution.new
    @two = Contribution.new
    @two_a = Contribution.new
    @two_b = Contribution.new
    @three = Contribution.new
    @one.stub!(:date).and_return(Date.new(1999,1,1))
    @two.stub!(:date).and_return(Date.new(1999,12,31))
    @two_a.stub!(:date).and_return(Date.new(1999,12,31))
    @two_b.stub!(:date).and_return(Date.new(1999,12,31))
    @three.stub!(:date).and_return(Date.new(2000,1,1))

    @one.stub!(:section_id).and_return(1)
    @two.stub!(:section_id).and_return(2)
    @two_a.stub!(:section_id).and_return(5)
    @two_b.stub!(:section_id).and_return(5)
    @three.stub!(:section_id).and_return(4)
    contributions = [@two, @three, @one, @two_a, @two_b]
    @member = Member.new(:name => 'Mr Boyes', :contribution_count => contributions.size)
    @member.stub!(:contributions).and_return(contributions)
  end

  it 'should return contributions grouped by year and section, ascending' do
    groups = @member.contributions_in_groups_by_year_and_section
    groups.size.should == 2
    groups[0].size.should == 3
    groups[0][0].size.should == 1
    groups[0][0].first.should == @one

    groups[0][1].size.should == 1
    groups[0][1].first.should == @two

    groups[0][2].size.should == 2

    groups[1].size.should == 1
    groups[1][0].size.should == 1
    groups[1][0].first.should == @three
    # groups.should == [[[@one], [@two], [@two_a, @two_b]], [[@three]]]
  end
end
