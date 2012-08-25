require File.dirname(__FILE__) + '/../spec_helper'

describe MembersController do

  it_should_behave_like "All controllers"
  
  describe "when routing" do 

    it "should map { :controller => 'members', :action => 'index'} to /members" do
      params = { :controller => 'members', :action => 'index' }
      route_for(params).should == '/members'
    end

    it "should map { :controller => 'members', :name => 'mr_boyes', :action => 'show'} to /members/mr_boyes" do
      params = { :controller => 'members', :action => 'show', :name => 'mr_boyes' }
      route_for(params).should == '/members/mr_boyes'
    end

    it "should map { :controller => 'members', :name => 'mr_boyes', :action => 'show', :year => '1997'} to /members/mr_boyes/1997" do
      params = { :controller => 'members', :action => 'show', :name => 'mr_boyes', :year => '1997' }
      route_for(params).should == '/members/mr_boyes/1997'
    end

  end

  describe "when handling /members" do 

    it 'should redirect to /people with a 301 response code' do 
      get :index
      response.should redirect_to('http://test.host/people')
      response.headers["Status"].should == "301 Moved Permanently"
    end
  
  end

  describe 'when handling /members/mr_boyes' do 
    
    def do_get
      get :show, :name => 'mr-boyes'
    end
  
    it 'should return a 301 response code and a redirect to /people/mr-boyes ' do 
      controller.stub!(:person_url).with('mr-boyes').and_return("http://test.host/people/mr-boyes")
      do_get
      response.should redirect_to('http://test.host/people/mr-boyes')
      response.headers["Status"].should == "301 Moved Permanently"
    end

  end

end
