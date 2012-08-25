require File.dirname(__FILE__) + '/../spec_helper'

describe ConstituenciesController, " in general" do 
  it_should_behave_like "All controllers"
end

describe ConstituenciesController, " in handling index requests" do 
 
  before do 
    @controller_name = 'constituencies'
    @model = Constituency
  end
  
  it_should_behave_like 'A controller with alphabetical index links'
  
end

describe ConstituenciesController, " when routing requests " do

  it "should map { :controller => 'constituencies', :action => 'index' } to /constituences" do
    params = { :controller => 'constituencies', :action => 'index' }
    route_for(params).should == "/constituencies"
  end
  
  it "should map { :controller => 'constituencies', :name => 'brent-north', :action => 'show'} to /constituencies/brent-north" do
    params = { :controller => 'constituencies', :action => 'show', :name => 'brent-north' }
    route_for(params).should == '/constituencies/brent-north'
  end

  it 'should map { :controller => "constituencies", :name => "mr_boyes", :action => "brent-north", :format => "js"} to /constituencies/brent-north' do
    params = { :controller => 'constituencies', :action => 'show', :name => 'brent-north', :format => "js" }
    route_for(params).should == '/constituencies/brent-north.js'
  end

end

describe ConstituenciesController, " when handling /constituencies/brent-north" do
  
  before(:all) do
    @constituency = mock_model(Constituency)
  end
  
  def do_get
    get 'show', :name => 'brent-north'
  end

  it 'should ask for the constituency and pass it to the view' do
    Constituency.should_receive(:find_constituency).with('brent-north').and_return(@constituency)
    do_get
    assigns[:constituency].should == @constituency
  end

  it 'should respond with an error message when given a name that does not match any constituency' do
    name = 'non_constituency'
    Constituency.should_receive(:find_constituency).with('non_constituency').and_return(nil)
    get 'show', :name => 'non_constituency'
    response.should render_template('no_constituency') 
  end

end

describe ConstituenciesController, " when handling /constituencies/brent-north.js" do
  
  before do
    @constituency = mock_model(Constituency)
    Constituency.stub!(:find_constituency).and_return(@constituency)
    @constituency.stub!(:to_json).and_return("some json content")
  end
  
  def do_get
    get :show, :name => 'brent-north', :format => 'js' 
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should ask the constituency for it's json" do
    @constituency.should_receive(:to_json)
    do_get
  end
  
  it 'should render the json with type header "text/x-json; charset=utf-8"' do
    do_get
    response.body.should == "some json content"
    response.headers["type"].should == "text/x-json; charset=utf-8"
  end
    
end

