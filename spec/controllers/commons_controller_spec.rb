require File.dirname(__FILE__) + '/../spec_helper'

describe CommonsController, "#route_for" do
  
  it "should map { :controller => 'commons', :action => 'show_commons_hansard', :year => '1999', :month => 'feb', day => '08' } to /commons/1999/feb/02" do
    params = { :controller => 'commons', :action => 'show_commons_hansard', :year => '1999', :month => 'feb', :day => '08' }
    route_for(params).should == "/commons/1999/feb/08"
  end
  
end

describe CommonsController, "handling GET /commons/1999/feb/08" do

  before do
    @sitting = mock_model(HouseOfCommonsSitting)
  end
  
  def do_get
    get :show_commons_hansard, :year => '1999', :month => 'feb', :day => '08'
  end

  it "should be successful" do
    HouseOfCommonsSitting.stub!(:find_by_date).and_return(@sitting)
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    HouseOfCommonsSitting.should_receive(:find_by_date).with("1999-02-08").and_return(@sitting)
    do_get
  end

end
