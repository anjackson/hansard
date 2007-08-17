require File.dirname(__FILE__) + '/../spec_helper'

describe SittingsController, "#route_for" do
  
  it "should map { :controller => 'sittings', :action => 'show', :id => 1, :format => 'xml' } to /sittings/1.xml" do
    route_for(:controller => "sittings", :action => "show", :id => 1, :format => "xml").should == "/sittings/1.xml"
  end
  
  it "should map { :controller => 'sittings', :action => 'show', :id => 1 } to /sittings/1" do
    route_for(:controller => "sittings", :action => "show", :id => 1).should == "/sittings/1"
  end
  
end

describe SittingsController, " handling GET /sittings/1.xml" do

  before do
    @sitting = mock_model(Sitting)
    Sitting.stub!(:find).and_return(@sitting)
    @sitting.stub!(:to_xml)
  end
  
  def do_get
    @request.env["HTTP_ACCEPT"] = "application/xml"
    get :show, :id => "1"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    Sitting.should_receive(:find).with("1").and_return(@sitting)
    do_get
  end
  
  it "should ask the sitting model for it's xml" do
    @sitting.should_receive(:to_xml).and_return("xml")
    do_get
  end
  
end
