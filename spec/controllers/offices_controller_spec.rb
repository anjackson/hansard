require File.dirname(__FILE__) + '/../spec_helper'

describe OfficesController, " in general" do 
  it_should_behave_like "All controllers"
end

describe OfficesController, " in handling index requests" do 
 
  before do 
    @controller_name = 'offices'
    @model = Office
  end
  
  it_should_behave_like 'A controller with alphabetical index links'
  
end

describe OfficesController, " when routing requests " do

  it "should map { :controller => 'offices', :action => 'index' } to /offices" do
    params = { :controller => 'offices', :action => 'index' }
    route_for(params).should == "/offices"
  end
  
  it "should map { :controller => 'offices', :action => 'show', :name => 'the-solicitor-general'} to /offices/the-solicitor-general" do 
    params = { :controller => 'offices', :action => 'show', :name => 'the-solicitor-general' }
    route_for(params).should == '/offices/the-solicitor-general'
  end
  
end


describe OfficesController, " when handling /offices/the-solicitor-general" do
  
  before(:all) do
    @office = mock_model(Office)
  end
  
  def do_get
    get 'show', :name => 'the-solicitor-general'
  end

  it 'should ask for the office and pass it to the view' do
    Office.should_receive(:find_office).with('the-solicitor-general').and_return(@office)
    do_get
    assigns[:office].should == @office
  end

  it 'should respond with an error message when given a name that does not match any office' do
    name = 'non_office'
    Office.should_receive(:find_office).with('non_office').and_return(nil)
    get 'show', :name => 'non_office'
    response.should render_template('offices/no_office') 
  end

end



