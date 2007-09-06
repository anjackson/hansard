require File.dirname(__FILE__) + '/../spec_helper'

describe WrittenAnswersController, "#route_for" do
  
  it "should map { :controller => 'written_answers', :action => 'index'} to /writtenanswers" do
    params = { :controller => 'written_answers', :action => 'index' }
    route_for(params).should == '/writtenanswers'
  end

  it "should map { :controller => 'written_answers', :action => 'show', :year => '1999', :month => 'feb', :day => '08' } to /writtenanswers/1999/feb/02" do
    params = { :controller => 'written_answers', :action => 'show', :year => '1999', :month => 'feb', :day => '08' }
    route_for(params).should == "/writtenanswers/1999/feb/08"
  end
 
  it "should map { :controller => 'written_answers', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' } to /writtenanswers/1999/feb/02.xml" do
    params = { :controller => 'written_answers', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' }
    route_for(params).should == "/writtenanswers/1999/feb/08.xml"
  end
  
  it "should map { :controller => 'writtenanswers', :action => 'show_source', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' } to /writtenanswers/source/1999/feb/08.xml" do
    params = { :controller => 'written_answers', :action => 'show_source', :year => '1999', :month => 'feb', :day => '08', :format => 'xml'}
    route_for(params).should == "/writtenanswers/source/1999/feb/08.xml"
  end

end

describe WrittenAnswersController, " handling GET /writtenanswers" do 
  
  before do 
    @sitting = mock_model(WrittenAnswersSitting)
    WrittenAnswersSitting.stub!(:find).and_return([@sitting])
  end
  
  def do_get
    get :index
  end
  
  it "should be successful" do 
    do_get
    response.should be_success
  end

  it "should get all the sittings in ascending date order" do 
    WrittenAnswersSitting.should_receive(:find).with(:all, :order => "date asc").and_return([@sitting])
    do_get
  end
  
  it "should render with the 'index' template" do 
    do_get
    response.should render_template('index')
  end 

end

describe WrittenAnswersController, "handling GET /writtenanswers/1999/feb/08" do

  before do
    @sitting = mock_model(WrittenAnswersSitting)
    WrittenAnswersSitting.stub!(:find_by_date).and_return(@sitting)
  end
  
  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    WrittenAnswersSitting.should_receive(:find_by_date).with("1999-02-08").and_return(@sitting)
    do_get
  end
  
  it "should render with the 'show' template" do
    do_get
    response.should render_template('show')
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

describe WrittenAnswersController, "handling GET /writtenanswers/1999/feb/08.xml" do

  before do
    @sitting = mock_model(WrittenAnswersSitting)
    @sitting.stub!(:to_xml)
    WrittenAnswersSitting.stub!(:find_by_date).and_return(@sitting)
  end
  
  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :format => 'xml'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    WrittenAnswersSitting.should_receive(:find_by_date).with("1999-02-08").and_return(@sitting)
    do_get
  end
  
  it "should call the ask the sitting for it's xml" do 
    @sitting.should_receive(:to_xml)
    do_get
  end

end

describe WrittenAnswersController, "handling GET /writtenanswers/source/1999/feb/08.xml" do

  before do
    @sitting = mock_model(WrittenAnswersSitting)
    @data_file = mock("data file")
    @sitting.stub!(:data_file).and_return(@data_file)
    @file = mock("a file")
    @file.stub!(:read)
    @data_file.stub!(:file).and_return(@file)
    WrittenAnswersSitting.stub!(:find_by_date).and_return(@sitting)
  end
  
  def do_get
    get :show_source, :year => '1999', :month => 'feb', :day => '08', :format => 'xml'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    WrittenAnswersSitting.should_receive(:find_by_date).with("1999-02-08").and_return(@sitting)
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


describe WrittenAnswersController, " handling GET /commons/year/month/day.xml with real data and views" do
  
  def get_source(date, file)
    if date.month < 10
      month = "0"+date.month.to_s
    else
      month = date.month.to_s
    end
    if date.day < 10
      day = "0"+date.day.to_s
    else
      day = date.day.to_s
    end
    File.dirname(__FILE__) + "/../../data/1982_11_03_lords_4.9mb/#{file.upcase}/writtenanswers_#{date.year}_#{month}_#{day}.xml"
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
    sitting = Hansard::WrittenAnswersParser.new(source_file).parse
    sitting.save!
    do_get(date)
    source = File.read(source_file)
    output = response.body
    normalize(source, output)
    output[0..32000].should eql(source[0..32000])
  end
  # 
  # it "should render an xml document identical to the original xml for writtenanswers_1985_12_16.xml" do
  #   output_should_equal_source_for(Date.new(1982, 9, 4), "s5lv0436p0")
  # end
  

end
