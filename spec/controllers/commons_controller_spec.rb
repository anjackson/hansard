require File.dirname(__FILE__) + '/../spec_helper'

describe CommonsController, "#route_for" do
  
  it "should map { :controller => 'commons', :action => 'index' } to /" do
    params = { :controller => 'commons', :action => 'index'}
    route_for(params).should == "/"
  end
  
  it "should map { :controller => 'commons', :action => 'show_commons_hansard', :year => '1999', :month => 'feb', :day => '08' } to /commons/1999/feb/02" do
    params = { :controller => 'commons', :action => 'show_commons_hansard', :year => '1999', :month => 'feb', :day => '08' }
    route_for(params).should == "/commons/1999/feb/08"
  end
 
  it "should map { :controller => 'commons', :action => 'show_commons_hansard', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' } to /commons/1999/feb/02.xml" do
    params = { :controller => 'commons', :action => 'show_commons_hansard', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' }
    route_for(params).should == "/commons/1999/feb/08.xml"
  end
  
  it "should map { :controller => 'commons', :action => 'show_commons_hansard_source', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' } to /commons/source/1999/feb/08.xml" do
    params = { :controller => 'commons', :action => 'show_commons_hansard_source', :year => '1999', :month => 'feb', :day => '08', :format => 'xml'}
    route_for(params).should == "/commons/source/1999/feb/08.xml"
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
  
  it "should assign an empty marker options hash to the view" do
    do_get
    assigns[:marker_options].should == {}
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

describe CommonsController, "handling GET /commons/source/1999/feb/08.xml" do

  before do
    @sitting = mock_model(HouseOfCommonsSitting)
    @data_file = mock("data file")
    @sitting.stub!(:data_file).and_return(@data_file)
    @file = mock("a file")
    @file.stub!(:read)
    @data_file.stub!(:file).and_return(@file)
    HouseOfCommonsSitting.stub!(:find_by_date).and_return(@sitting)
  end
  
  def do_get
    get :show_commons_hansard_source, :year => '1999', :month => 'feb', :day => '08', :format => 'xml'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    HouseOfCommonsSitting.should_receive(:find_by_date).with("1999-02-08").and_return(@sitting)
    do_get
  end
  
  it "should ask the sitting for it's data file" do
    @sitting.should_receive(:data_file).and_return(@data_file)
    do_get
  end
  
  it "should ask the data file for it's file" do
    @data_file.should_receive(:file).and_return(@file)
    do_get
  end
  
  it "should read the contents of the file and render them" do
    @file.should_receive(:read).and_return("data")
    @controller.expect_render(:xml => "data")
    do_get
  end
  
end

describe CommonsController, " handling GET /commons/year/month/day.xml with real data and views" do
  
  def get_source(date, file)
    if date.month < 10
      month = "0"+date.month.to_s
    else
      month = date.month.to_s
    end
    File.dirname(__FILE__) + "/../../data/#{file}/housecommons_#{date.year}_#{month}_#{date.day}.xml"
  end
  
  def do_get(date)
    month = Date::ABBR_MONTHNAMES[date.month].downcase
    get :show_commons_hansard, :year => date.year, :month => month, :day => date.day, :format => 'xml'
  end
  
  def normalize source, output
    substitutions = [['<td/>', '<td></td>'], # make empty td tags consisten
                     [/<(.*) (align=".*") (.*=".*")>/, '<\1 \3 \2>'], #brutally reorder some tags
                     [">", ">\n"], # all tags followed by a newline
                     ["<","\n<"], # all tags preceded by a newline
                     [/^\s*/, ''], # strip whitespace at start of line
                     [/\s*$/, '']] # strip whitespace at end of line
                     
    substitutions.each do |match, replacement|
      source.gsub!(match, replacement)
      output.gsub!(match, replacement)
    end
  end
  
  def output_should_equal_source_for(date, orig_file)
    source_file = get_source(date, orig_file)
    sitting = Hansard::HouseCommonsParser.new(source_file).parse
    sitting.save!
    do_get(date)
    source = File.read(source_file)
    output = response.body
    normalize(source, output)
    output.should eql(source)
  end
  
  # it "should render an xml document identical to the original xml for housecommons_1985_12_16.xml" do
  #   output_should_equal_source_for(Date.new(1985, 12, 16), "s6cv0089p0")
  # end
  
  # it "should render an xml document identical to the original xml for housecommons_2004_07_19.xml" do
  #    output_should_equal_source_for(Date.new(2004, 7, 19), "s6cv0424p1")
  #  end
  #  
end
