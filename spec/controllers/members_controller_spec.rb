require File.dirname(__FILE__) + '/../spec_helper'

describe MembersController do

  it "should map { :controller => 'members', :action => 'index'} to /members" do
    params = { :controller => 'members', :action => 'index' }
    route_for(params).should == '/members'
  end

  it "should map { :controller => 'members', :name => 'mr_boyes', :action => 'show_member'} to /members/mr_boyes" do
    params = { :controller => 'members', :action => 'show_member', :name => 'mr_boyes' }
    route_for(params).should == '/members/mr_boyes'
  end

  it 'should handle index action' do
    members = [mock(Member)]
    @controller.should_receive(:find_all_members).and_return(members)
    get :index
    assigns[:members].should == members
  end

  it 'should handle show_member action' do
    name = 'mr_boyes'
    member = mock(Member)
    contributions = []
    member.stub!(:contributions_in_groups_by_year).and_return(contributions)
    @controller.should_receive(:find_member).with(name).and_return(member)
    get :show_member, :name => name
    assigns[:member].should == member
    assigns[:contributions_in_groups_by_year].should == contributions
  end
end
