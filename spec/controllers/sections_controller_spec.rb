require File.dirname(__FILE__) + '/../spec_helper'

describe SectionsController, "#route_for" do
  
  it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons' } to /commons/1999/feb/08/test-slug" do
    params =  { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons' }
    route_for(params).should == "/commons/1999/feb/08/test-slug"
  end 
  
  it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'writtenanswers' } to /writtenanswers/1999/feb/08/test-slug" do
    params = {:controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'writtenanswers' }
    route_for(params).should == "/writtenanswers/1999/feb/08/test-slug"
  end

end

describe SectionsController, "handling GET /commons/1999/feb/08/test-slug" do

  before do
    @sitting = mock_model(HouseOfCommonsSitting)
    HouseOfCommonsSitting.stub!(:find_by_date).and_return(@sitting)
    @sections = mock("sitting sections")
    @sitting.stub!(:sections).and_return(@sections)
    @sitting.sections.stub!(:find_by_slug)
  end
  
  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "commons"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    HouseOfCommonsSitting.should_receive(:find_by_date).with("1999-02-08").and_return(@sitting)
    do_get
  end
  
  it "should render with the 'show' template" do
    do_get
    response.should render_template('show')
  end
  
  it "should find the section using the slug" do
    @sitting.sections.should_receive(:find_by_slug)
    do_get
  end

  it "should assign the section for the view" do
    section = Section.new
    @sitting.sections.should_receive(:find_by_slug).and_return(section)
    do_get
    assigns[:section].should_not be_nil
    assigns[:section].should equal(section)
  end
  
  it "should assign an empty marker options hash to the view" do
    do_get
    assigns[:marker_options].should == {}
  end

end

describe SectionsController, "handling GET /writtenanswers/1999/feb/08/test-slug" do

  before do
    @sitting = mock_model(WrittenAnswersSitting)
    WrittenAnswersSitting.stub!(:find_by_date).and_return(@sitting)
    @sections = mock("sitting sections")
    @sitting.stub!(:sections).and_return(@sections)
    @sitting.sections.stub!(:find_by_slug)
  end
  
  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "writtenanswers"
  end
  
  it "should find the sitting requested" do
    WrittenAnswersSitting.should_receive(:find_by_date).with("1999-02-08").and_return(@sitting)
    do_get
  end
  
end