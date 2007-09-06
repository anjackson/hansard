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

