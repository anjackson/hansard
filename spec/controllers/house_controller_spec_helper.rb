require File.dirname(__FILE__) + '/../spec_helper'

describe "controller that has routes correctly configured", :shared => true do

  it "should map { :controller => @house_type, :action => 'index' } to /@house_type" do
    params = { :controller => @house_type, :action => 'index'}
    route_for(params).should == "/#{@house_type}"
  end

  it "should map { :controller => @house_type, :action => 'show', :year => '1999', :month => 'feb', :day => '08' } to /@house_type/1999/feb/02" do
    params = { :controller => @house_type, :action => 'show', :year => '1999', :month => 'feb', :day => '08' }
    route_for(params).should == "/#{@house_type}/1999/feb/08"
  end

  it "should map { :controller => @house_type, :action => 'show', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' } to /@house_type/1999/feb/02.xml" do
    params = { :controller => @house_type, :action => 'show', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' }
    route_for(params).should == "/#{@house_type}/1999/feb/08.xml"
  end

  it "should map { :controller => @house_type, :action => 'show_source', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' } to /@house_type/source/1999/feb/08.xml" do
    params = { :controller => @house_type, :action => 'show_source', :year => '1999', :month => 'feb', :day => '08', :format => 'xml'}
    route_for(params).should == "/#{@house_type}/source/1999/feb/08.xml"
  end

end

describe " handling GET /<house_type>", :shared => true do

  before do
    @sitting = mock_model(@sitting_model)
    sittings_by_year = [[@sitting]]
    @sitting_model.stub!(:all_grouped_by_year).and_return(sittings_by_year)
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

  it "should ask for all the sittings in cronological order" do
    sittings_by_year = [[@sitting]]
    @sitting_model.stub!(:all_grouped_by_year).and_return(sittings_by_year)
    do_get
  end

end

describe " handling GET /<house_type>/1999", :shared => true do

  before do
    @sitting = mock_model(@sitting_model)
    @sitting_model.stub!(:find_in_resolution).and_return([@sitting])
  end

  def do_get
    get :show, :year => '1999'
  end

  it "should look for sittings in the year passed" do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 1, 1), :year, nil).and_return([@sitting])
    do_get
  end

end

describe " handling GET /<house_type>/1999/feb", :shared => true do

  before do
    @sitting = mock_model(@sitting_model)
    @sitting_model.stub!(:find_in_resolution).and_return([@sitting])
  end

  def do_get
    get :show, :year => '1999', :month => 'feb'
  end

  it "should look for sittings in the year passed" do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 2, 1), :month, nil).and_return([@sitting])
    do_get
  end

end

describe " handling GET /<house_type>/1999/feb/08", :shared => true do

  before do
    @sitting = mock_model(@sitting_model)
    @sitting_model.stub!(:find_in_resolution).and_return([@sitting])
  end

  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should look for a sitting on the date passed" do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 2, 8), :day, nil).and_return([@sitting])
    do_get
  end

  it "should render with the 'show' template if there is one sitting" do
    do_get
    response.should render_template('show')
  end

  it "should assign day to true if there is one sitting" do
    do_get
    assigns[:day].should be_true
  end

  it "should render with the 'index' template if there is more than one sitting" do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 2, 8), :day, nil).and_return([@sitting, @sitting])
    do_get
    response.should render_template('index')
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

describe " handling GET /<house_type>/1999/feb/08/2", :shared => true do

  before do
    @sitting = mock_model(@sitting_model)
    @sitting_model.stub!(:find_in_resolution).and_return([@sitting])
  end

  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :part_id => "2"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should look for a sitting on the date passed" do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 2, 8), :day, 2).and_return([@sitting])
    do_get
  end

  it "should render with the 'show' template if there is one sitting" do
    do_get
    response.should render_template('show')
  end

  it "should assign day to true if there is one sitting" do
    do_get
    assigns[:day].should be_true
  end

  it "should render with the 'index' template if there is more than one sitting" do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 2, 8), :day, 2).and_return([@sitting, @sitting])
    do_get
    response.should render_template('index')
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

describe " handling GET /<house_type>/1999/feb/08.xml", :shared => true do

  before do
    @sitting = mock_model(@sitting_model)
    @sitting.stub!(:to_xml)
    @sitting_model.stub!(:find_in_resolution).and_return([@sitting])
  end

  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :format => 'xml'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should find the sitting requested" do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 2, 8), :day, nil).and_return([@sitting])
    do_get
  end

  it "should call the ask the sitting for it's xml" do
    @sitting.should_receive(:to_xml)
    do_get
  end

end

describe " handling GET /<house_type>/source/1999/feb/08.xml", :shared => true do

  before do
    @sitting = mock_model(@sitting_model)
    @data_file = mock("data file")
    @sitting.stub!(:data_file).and_return(@data_file)
    @file = mock("a file")
    @file.stub!(:read)
    @data_file.stub!(:file).and_return(@file)
    @sitting_model.stub!(:find_by_date).and_return(@sitting)
  end

  def do_get
    get :show_source, :year => '1999', :month => 'feb', :day => '08', :format => 'xml'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should find the sitting requested" do
    @sitting_model.should_receive(:find_by_date).with("1999-02-08").and_return(@sitting)
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

describe " handling GET /<house_type>/year/month/day.xml with real data and views", :shared => true do

  def get_source(date, file)
    if date.month < 10
      month = "0"+date.month.to_s
    else
      month = date.month.to_s
    end
    File.dirname(__FILE__) + "/../../data/#{file}/house#{house_type}_#{date.year}_#{month}_#{date.day}.xml"
  end

  def do_get(date)
    month = Date::ABBR_MONTHNAMES[date.month].downcase
    get :show, :year => date.year, :month => month, :day => date.day, :format => 'xml'
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
    sitting = @hansard_parser.new(source_file).parse
    sitting.save!
    do_get(date)
    source = File.read(source_file)
    output = response.body
    normalize(source, output)
    output.should eql(source)
  end

end
