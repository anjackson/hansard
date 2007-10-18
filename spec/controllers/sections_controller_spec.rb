require File.dirname(__FILE__) + '/../spec_helper'

describe SectionsController, "#route_for" do

  it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons' } to /commons/1999/feb/08/test-slug" do
    params =  { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons' }
    route_for(params).should == "/commons/1999/feb/08/test-slug"
  end

  it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'lords' } to /lords/1999/feb/08/test-slug" do
    params =  { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'lords' }
    route_for(params).should == "/lords/1999/feb/08/test-slug"
  end

  it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'written_answers' } to /written_answers/1999/feb/08/test-slug" do
    params = {:controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'written_answers' }
    route_for(params).should == "/written_answers/1999/feb/08/test-slug"
  end

  it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons', :action => 'nest' } to /commons/1999/feb/08/test-slug/nest" do
    params =  { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons', :action => 'nest' }
    route_for(params).should == "/commons/1999/feb/08/test-slug/nest"
  end

  it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons', :action => 'nest' } to /commons/1999/feb/08/test-slug/unnest" do
    params =  { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons', :action => 'unnest' }
    route_for(params).should == "/commons/1999/feb/08/test-slug/unnest"
  end
end

describe SectionsController, "handling GET /commons/1999/feb/08/test-slug" do

  before do
    @sitting = mock_model(HouseOfCommonsSitting)
    HouseOfCommonsSitting.stub!(:find_all_by_date).and_return([@sitting])
    @sitting.stub!(:sections).and_return(@sections)
    @section = mock_model(Section)
    @section.stub!(:title).and_return('Title')
    @sitting.sections.stub!(:find_by_slug).and_return(@section)
  end

  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "commons"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should find the sitting requested" do
    HouseOfCommonsSitting.should_receive(:find_all_by_date).with("1999-02-08").and_return([@sitting])
    do_get
  end

  it "should render with the 'show' template" do
    do_get
    response.should render_template('show')
  end

  it "should find the section using the slug" do
    @sitting.sections.should_receive(:find_by_slug).and_return(@section)
    do_get
  end

  it "should assign the section for the view" do
    @sitting.sections.should_receive(:find_by_slug).and_return(@section)
    do_get
    assigns[:section].should_not be_nil
    assigns[:section].should equal(@section)
  end

  it "should assign an empty marker options hash to the view" do
    do_get
    assigns[:marker_options].should == {}
  end

end

describe SectionsController, "handling GET /written_answers/1999/feb/08/test-slug" do

  before do
    @sitting = mock_model(WrittenAnswersSitting)
    WrittenAnswersSitting.stub!(:find_all_by_date).and_return([@sitting])
    @sections = mock("sitting sections")
    @sitting.stub!(:sections).and_return(@sections)
    @section = mock_model(Section)
    @section.stub!(:title).and_return('Title')
    @sitting.sections.stub!(:find_by_slug).and_return(@section)
  end

  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "written_answers"
  end

  it "should find the sitting requested" do
    WrittenAnswersSitting.should_receive(:find_all_by_date).with("1999-02-08").and_return([@sitting])
    do_get
  end

end

describe SectionsController, 'handling POST /commons/1999/feb/08/trade-and-industry/nest or unnest' do

  before do
    @sitting = mock_model(HouseOfCommonsSitting)
    @section = mock_model(Section)
    @section.stub!(:nest!)
    @section.stub!(:unnest!)
    @section.stub!(:slug).and_return('trade-and-industry')
    @section.stub!(:id).and_return(123)
    @section.stub!(:parent_section_id).and_return(nil)
    @controller.stub!(:find_sitting_and_section).and_return([@sitting, @section])
  end

  def do_post action
    post action, :year => '1999', :month => 'feb', :day => '08', :id => "trade-and-industry", :type => "commons"
  end

  it 'should on nest find sitting and section with appropriate parameters' do
    @controller.should_receive(:find_sitting_and_section).
        with('commons', Date.new(1999,2,8), "trade-and-industry").
        and_return([@sitting, @section])
    do_post :nest
  end

  it 'should nest section' do
    @section.should_receive(:nest!)
    do_post :nest
  end

  it "should on nest redirect to anchor id of section on edit view if section doesn't have a parent section" do
    do_post :nest
    response.should be_redirect
    response.should redirect_to('http://test.host/commons/1999/feb/08/edit#section_123')
  end

  it "should on nest redirect to anchor id of parent section on edit view" do
    @section.stub!(:parent_section_id).and_return(122)
    do_post :nest
    response.should be_redirect
    response.should redirect_to('http://test.host/commons/1999/feb/08/edit#section_122')
  end

  it 'should on unnest find sitting and section with appropriate parameters' do
    @controller.should_receive(:find_sitting_and_section).
        with('commons', Date.new(1999,2,8), "trade-and-industry").
        and_return([@sitting, @section])
    do_post :unnest
  end

  it 'should unnest section' do
    @section.should_receive(:unnest!)
    do_post :unnest
  end

  it "should on unnest redirect to anchor id of section on edit view if section doesn't have a parent section" do
    do_post :unnest
    response.should be_redirect
    response.should redirect_to('http://test.host/commons/1999/feb/08/edit#section_123')
  end

  it "should on unnest redirect to anchor id of parent section on edit view" do
    @section.stub!(:parent_section_id).and_return(122)
    do_post :unnest
    response.should be_redirect
    response.should redirect_to('http://test.host/commons/1999/feb/08/edit#section_122')
  end

end
