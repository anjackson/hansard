require File.dirname(__FILE__) + '/../spec_helper'

describe PeopleController, " in general" do 
  it_should_behave_like "All controllers"
end

describe PeopleController, " in handling index requests" do 
 
  before do 
    @controller_name = 'people'
    @model = Person
    @name_method = :ascii_alphabetical_name
  end
  
  it_should_behave_like 'A controller with alphabetical index links'
  
end

describe PeopleController do

  it "should map { :controller => 'people', :action => 'index'} to /people" do
    params = { :controller => 'people', :action => 'index' }
    route_for(params).should == '/people'
  end

  it "should map { :controller => 'people', :name => 'mr_boyes', :action => 'show'} to /people/mr_boyes" do
    params = { :controller => 'people', :action => 'show', :name => 'mr_boyes' }
    route_for(params).should == '/people/mr_boyes'
  end
  
  it "should map { :controller => 'people', :name => 'mr_boyes', :action => 'show', :year => '1997'} to /people/mr_boyes/1997" do
    params = { :controller => 'people', :action => 'show', :name => 'mr_boyes', :year => '1997' }
    route_for(params).should == '/people/mr_boyes/1997'
  end
  
  it 'should map { :controller => "people", :name => "mr_boyes", :action => "show", :format => "js"} to /people/mr_boyes.js' do
    params = { :controller => 'people', :action => 'show', :name => 'mr_boyes', :format => "js" }
    route_for(params).should == '/people/mr_boyes.js'
  end
  
  it 'should handle show action with year' do
    name = 'mr_boyes'
    person = mock_model(Person)
    Person.stub!(:find_by_slug).and_return(person)
    get :show, :name => name, :year => "2004"
    assigns[:year].should == 2004
  end
  
end

describe PeopleController, " when handling /people/mr_boyes.js" do

  before do
    @person = mock_model(Person)
    Person.stub!(:find_by_slug).and_return(@person)
    @person.stub!(:to_json).and_return("some json content")
  end

  def do_get
    get :show, :name => 'mr_boyes', :format => 'js'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should ask the person for it's json" do
    @person.should_receive(:to_json)
    do_get
  end

  it 'should render the json with type header "text/x-json; charset=utf-8"' do
    do_get
    response.body.should == "some json content"
    response.headers["type"].should == "text/x-json; charset=utf-8"
  end

end

describe PeopleController, " when handling /people/lord-peter-wimsey" do 
  
  before do 
    @person = mock_model(Person)
  end
  
  def do_get
    get :show, :name => 'lord-peter-wimsey'
  end
  
  it 'should ask for the person by slug passing the name parameter' do 
    Person.should_receive(:find_by_slug).with('lord-peter-wimsey').and_return(@person)
    do_get
  end
  
  it 'should assign the person found to the view' do 
    Person.stub!(:find_by_slug).and_return(@person)
    do_get
    assigns[:person].should == @person
  end
  
  it 'should respond with an error message when given a name that does not match any person' do
    name = 'non-person'
    Person.stub!(:find_by_slug).and_return(nil)
    do_get
    response.should render_template('no_person') 
  end
  
end
