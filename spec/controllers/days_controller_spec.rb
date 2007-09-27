require File.dirname(__FILE__) + '/../spec_helper'

describe DaysController, "#route_for" do
  
  it "should map { :controller => 'days', :action => 'index' } to /" do
    params = { :controller => 'days', :action => 'index'}
    route_for(params).should == "/"
  end
  
  it "should map { :controller => 'days', :action => 'show', :year => '1999', :month => 'feb', :day => '08' } to /1999/feb/08" do
    params =  { :controller => 'days', :action => 'show', :year => '1999', :month => 'feb', :day => '08' }
    route_for(params).should == "/1999/feb/08"
  end

end

describe DaysController, " handling GET /" do
  
  def do_get
    get :index
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should render with the 'index' template" do
    do_get
    response.should render_template('index')
  end
  
  it "should ask for the most recent sitting" do
    Sitting.should_receive(:most_recent)
    do_get
  end
  
  it "should assign the sitting to the view" do
    sitting = mock_model(Sitting)
    Sitting.stub!(:most_recent).and_return(sitting)
    do_get
    assigns[:sitting].should == sitting
  end
  
end

describe DaysController, " handling GET /1999/feb/08" do
  
  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08'
  end
  
  it "should be successful" do
     do_get
     response.should be_success
  end

  it "should render with the 'show' template" do
    do_get
    response.should render_template('show')
  end

  it "should find the sittings present on the date" do
    Sitting.should_receive(:find_all_present_on_date)
    do_get
  end
  
  it "should assign the sittings to the view" do
    Sitting.stub!(:find_all_present_on_date).and_return("sittings")
    do_get
    assigns[:sittings].should == "sittings"
  end
  
  it 'should redirect html requests for on_date to the canonical date url' do
    get :show, :year => '1999', :month => '2', :day => '08'
    response.should redirect_to({:action => "show", :year => '1999', :month => 'feb', :day => '08'})
    response.headers["Status"].should == "301 Moved Permanently"
  end
  
end
