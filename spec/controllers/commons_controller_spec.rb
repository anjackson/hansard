require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/housecommons_parser'

describe CommonsController, "#route_for" do
  
  it "should map { :controller => 'commons', :action => 'show_commons_hansard', :year => '1999', :month => 'feb', day => '08' } to /commons/1999/feb/02" do
    params = { :controller => 'commons', :action => 'show_commons_hansard', :year => '1999', :month => 'feb', :day => '08' }
    route_for(params).should == "/commons/1999/feb/08"
  end
 
  it "should map { :controller => 'commons', :action => 'show_commons_hansard', :year => '1999', :month => 'feb', day => '08', :format => 'xml' } to /commons/1999/feb/02.xml" do
    params = { :controller => 'commons', :action => 'show_commons_hansard', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' }
    route_for(params).should == "/commons/1999/feb/08.xml"
  end

end

describe CommonsController, "handling GET /commons/1999/feb/08" do

  before do
    @sitting = mock_model(HouseOfCommonsSitting)
    HouseOfCommonsSitting.stub!(:find_by_date).and_return(@sitting)
  end
  
  def do_get
    get :show_commons_hansard, :year => '1999', :month => 'feb', :day => '08'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    HouseOfCommonsSitting.should_receive(:find_by_date).with("1999-02-08").and_return(@sitting)
    do_get
  end
  
  it "should render with the 'show_commons_hansard' template" do
    do_get
    response.should render_template('show_commons_hansard')
  end

  it "should assign the sitting for the view" do
    do_get
    assigns[:sitting].should equal(@sitting)
  end
  
end

describe CommonsController, "handling GET /commons/1999/feb/08.xml" do

  before do
    @sitting = mock_model(HouseOfCommonsSitting)
    @sitting.stub!(:to_xml)
    HouseOfCommonsSitting.stub!(:find_by_date).and_return(@sitting)
  end
  
  def do_get
    get :show_commons_hansard, :year => '1999', :month => 'feb', :day => '08', :format => 'xml'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    HouseOfCommonsSitting.should_receive(:find_by_date).with("1999-02-08").and_return(@sitting)
    do_get
  end
  
  it "should call the ask the sitting for it's xml" do 
    @sitting.should_receive(:to_xml)
    do_get
  end

end
# 
# describe CommonsController, " handling GET /commons/1985/dec/16.xml with real data and views" do
# 
#   before do
#     @source_file = File.dirname(__FILE__) + "/../../data/s6cv0089p0/housecommons_1985_12_16.xml"
#     @sitting = Hansard::HouseCommonsParser.new(@source_file).parse
#     @sitting.save!
#   end
#   
#   def do_get
#     get :show_commons_hansard, :year => '1985', :month => 'dec', :day => '16', :format => 'xml'
#   end
#   
#   it "should render an xml document identical to the original xml" do
#     do_get
#     source = File.read(@source_file)
#     output = response.body
#     substitutions = [
#                      [">", ">\n"],
#                      ["<","\n<"],
#                      [/^\s*/, ''],
#                       [/\s*$/, '']]
#     substitutions.each do |match, replacement|
#       source.gsub!(match, replacement)
#       output.gsub!(match, replacement)
#     end
#     output.should eql(source)
#   end
#   
# end
