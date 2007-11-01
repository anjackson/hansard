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

end

describe SectionsController, " when combining sidenote markers" do
  
  before do
    @sitting = mock_model(HouseOfCommonsSitting)
    HouseOfCommonsSitting.stub!(:find_all_by_date).and_return([@sitting])
    @sitting.stub!(:sections).and_return(@sections)
    @section = mock_model(Section)
    @section.stub!(:title).and_return('Titl<lb/>e')
    @section.stub!(:plain_title).and_return('Title')
    @sitting.sections.stub!(:find_by_slug).and_return(@section)
  end
  
  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "commons"
  end
  
  it 'should return one sidenote with a linebreak if two sidenotes appear together ' do
    original = "<p><span class='sidenote'><a name='column_911' href='#column_911'>Col. 911</a></span>   <span class='sidenote'><a href='/images/S6CV0089P0I0466.jpg' alt='S6CV0089P0I0466' title='S6CV0089P0I0466' class='image-thumbnail'><figure><br/><legend>Img. S6CV0089P0I0466</legend></figure></a></span></p>"
    expected = "<p><span class='sidenote'><a name='column_911' href='#column_911'>Col. 911</a><br /><a href='/images/S6CV0089P0I0466.jpg' alt='S6CV0089P0I0466' title='S6CV0089P0I0466' class='image-thumbnail'><figure><br/><legend>Img. S6CV0089P0I0466</legend></figure></a></span></p>"  
    do_get
    @controller.response.body = original
    @controller.send(:combine_markers).should match(/#{expected}/)
  end
  
end

describe SectionsController, "handling GET /commons/1999/feb/08/test-slug" do

  before do
    @sitting = mock_model(HouseOfCommonsSitting)
    HouseOfCommonsSitting.stub!(:find_all_by_date).and_return([@sitting])
    @sitting.stub!(:sections).and_return(@sections)
    @section = mock_model(Section)
    @section.stub!(:title).and_return('Titl<lb/>e')
    @section.stub!(:plain_title).and_return('Title')
    @sitting.sections.stub!(:find_by_slug).and_return(@section)
  end

  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "commons"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it 'should not assign sitting in the view' do
    do_get
    assigns[:sitting].should be_nil
  end

  it "should find the sitting requested" do
    HouseOfCommonsSitting.should_receive(:find_all_by_date).with("1999-02-08").and_return([@sitting])
    do_get
  end

  it "should render with the 'show' template" do
    do_get
    response.should render_template('show')
  end

  it "should assign the plain title (no tags) of the section to the view" do
    do_get
    assigns[:title].should_not be_nil
    assigns[:title].should == @section.plain_title
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
    @section.stub!(:plain_title).and_return('Title')
    @sitting.sections.stub!(:find_by_slug).and_return(@section)
  end

  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "written_answers"
  end
  
  it 'should not assign sitting in the view' do
    do_get
    assigns[:sitting].should be_nil
  end

  it "should find the sitting requested" do
    WrittenAnswersSitting.should_receive(:find_all_by_date).with("1999-02-08").and_return([@sitting])
    do_get
  end

end


