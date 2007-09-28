require File.dirname(__FILE__) + '/../spec_helper'

describe "a date-based controller", :shared => true do
  
  it 'should redirect html requests for show to the canonical date url' do
    get :show, :year => '1999', :month => '2', :day => '08'
    response.should redirect_to({:action => "show", :year => '1999', :month => 'feb', :day => '08'})
    response.headers["Status"].should == "301 Moved Permanently"
  end
  
  it 'should redirect  requests for show with a non-existent date to the index action' do
    get :show, :year => '1999', :month => 'feb', :day => '29'
    response.should redirect_to({:action => "index"})
  end
  
  it "should treat a request with just a year and month as a request at the month resolution" do
    get :show, :year => '1999', :month => 'feb'
    assigns[:resolution].should == :month
  end
  
  it "should treat a request with just a year as a request at the year resolution" do
    get :show, :year => '1999'
    assigns[:resolution].should == :year
  end
  
end
