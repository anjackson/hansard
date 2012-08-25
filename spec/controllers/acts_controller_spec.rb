require File.dirname(__FILE__) + '/../spec_helper'

describe ActsController do 
  
  describe " in general" do 
    it_should_behave_like "All controllers"
  end

  describe " in handling index requests" do 
 
    before do 
      @controller_name = 'acts'
      @model = Act  
    end
  
    it_should_behave_like 'A controller with alphabetical index links'
  
  end

  describe " when routing requests " do

    it "should map { :controller => 'acts', :action => 'index' } to /acts" do
      params = { :controller => 'acts', :action => 'index' }
      route_for(params).should == "/acts"
    end

  
    it "should map { :controller => 'acts', :action => 'show', :name => 'the-welfare-act'} to /acts/the-welfare-act" do 
      params = { :controller => 'acts', :action => 'show', :name => 'the-welfare-act' }
      route_for(params).should == '/acts/the-welfare-act'
    end

  end

  describe " when handling /acts/the-welfare-act" do
  
    before do
      @act = mock_model(Act, :others_by_name => 'others')
    end
  
    def do_get
      get 'show', :name => 'the-welfare-act'
    end

    it 'should ask for the act and pass it to the view' do
      Act.stub!(:find_by_slug).and_return(@act)
      do_get
      assigns[:act].should == @act
    end

    it 'should respond with an error message when given a name that does not match any act' do
      name = 'non_act'
      Act.stub!(:find_by_slug).and_return(nil)
      get 'show', :name => 'non_act'
      response.should render_template('acts/no_act') 
    end

    it 'should ask for any other acts by the same name and pass them to the view' do 
      Act.stub!(:find_by_slug).and_return(@act)
      do_get
      assigns[:other_acts].should == 'others'
    end

  end

end

