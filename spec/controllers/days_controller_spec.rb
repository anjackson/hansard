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
  
  before do
    @mock_sitting = mock_model(Sitting)
    @mock_sitting.stub!(:date).and_return("the date")
    @controller.stub!(:get_calendar_data)
    Sitting.stub!(:most_recent).and_return(@mock_sitting)
  end
  
  def do_get
    get :index
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should render with the 'show' template" do
    do_get
    response.should render_template('show')
  end
  
  it "should get the calendar data" do
    @controller.should_receive(:get_calendar_data)
    do_get
  end
  
  it "should ask for the most recent sitting" do
    Sitting.should_receive(:most_recent).and_return(@mock_sitting)
    do_get
  end
  
  it "should assign the most recent sitting's date to the view" do
    do_get
    assigns[:date].should == "the date"
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
  
  it_should_behave_like "a date-based controller"

end
