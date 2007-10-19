require File.dirname(__FILE__) + '/../spec_helper'

describe MembersController do

  it "should map { :controller => 'members', :action => 'index'} to /members" do
    params = { :controller => 'members', :action => 'index' }
    route_for(params).should == '/members'
  end

  it "should map { :controller => 'members', :name => 'mr_boyes'} to /members/mr_boyes" do
    params = { :controller => 'members', :action => 'show', :name => 'mr_boyes' }
    route_for(params).should == '/members/mr_boyes'
  end
end
