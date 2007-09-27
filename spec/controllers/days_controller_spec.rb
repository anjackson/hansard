require File.dirname(__FILE__) + '/../spec_helper'

describe DaysController, "#route_for" do
  
  it "should map { :controller => 'days', :action => 'index' } to /" do
    params = { :controller => 'days', :action => 'index'}
    route_for(params).should == "/"
  end

end

describe DaysController, " handling GET /" do

  before do 
  end
  
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