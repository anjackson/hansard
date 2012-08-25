require File.dirname(__FILE__) + '/../spec_helper'

describe MembershipsController do 
  
  describe " in general" do
    it_should_behave_like "All controllers"
  end

  describe "when routing requests " do

    it "should map { :controller => 'memberships', :action => 'show', :day => '08', :month => 'feb', :year => '1999' } to /all-members/199/feb/08" do
      params = { :action => 'show', 
                 :controller => 'memberships', 
                 :day => '08', 
                 :month => 'feb', 
                 :year => '1999' }
      route_for(params).should == "/all-members/1999/feb/08"
    end
    
    it "should map { :controller => 'memberships', :action => 'show', :day => '08', :month => 'feb', :year => '1999', :format => 'js' } to /all-members/199/feb/08.js" do
      params = { :action => 'show', 
                 :controller => 'memberships', 
                 :day => '08', 
                 :month => 'feb', 
                 :year => '1999', 
                 :format => 'js' }
      route_for(params).should == '/all-members/1999/feb/08.js'
    end
  
  end
  
  describe 'when handling /all-members/1999/feb/08' do 
  
    def do_get
      get 'show', { :controller => 'memberships', 
                    :day => '08', 
                    :month => 'feb', 
                    :year => '1999' }
    end
    
    before do 
      CommonsMembership.stub!(:members_on_date).and_return([])
    end
    
    it 'should ask for all commons memberships on the date' do 
      CommonsMembership.should_receive(:members_on_date_by_constituency).with(Date.new(1999, 2, 8)).and_return([])
      do_get
    end
    
    it 'should render with the memberships/show template' do 
      do_get
      response.should render_template('memberships/show')
    end
    
  end
  
  describe 'when handling /all-members/1999/feb/08' do 
    
    before do 
      LordsMembership.stub!(:members_on_date_by_person).and_return([0,[]])
      CommonsMembership.stub!(:members_on_date_by_constituency).and_return([0,[]])
    end
    
    def do_get
      get 'show', { :controller => 'memberships', 
                    :day => '08', 
                    :month => 'feb', 
                    :year => '1999',
                    :format => 'js' }
    end
    
    it 'should ask for the commons members on that date by constituency' do 
      CommonsMembership.should_receive(:members_on_date_by_constituency).with(Date.new(1999, 2, 8))
      do_get
    end
    
    it 'should ask for the lords members on that date by person' do 
      LordsMembership.should_receive(:members_on_date_by_person).with(Date.new(1999, 2, 8))
      do_get
    end
  
    it 'should return a json data structure' do 
      commons_membership = CommonsMembership.new(:person => Person.new, 
                                         :constituency => Constituency.new)
      CommonsMembership.stub!(:members_on_date_by_constituency).and_return([1, ['constituency', commons_membership]])
      commons_membership.stub!(:to_json).and_return('some json')
      do_get
      response.headers["type"].should == "text/x-json; charset=utf-8"
      response.body.should match(/some json/)
    end
    
  end
  
end