require File.dirname(__FILE__) + '/../spec_helper'

describe "handling GET /commons/1999/feb/08/test-slug with or without a format suffix", :shared => true do

  it "should be successful" do
    do_get
    response.should be_success
  end

  it 'should render a 404 for a url referencing a section that does not exist' do
    @sitting.stub!(:find_section_by_slug).and_return(nil)
    do_get
    response.code.should == '404'
  end

  it 'should assign sitting in the view' do
    do_get
    assigns[:sitting].should_not be_nil
  end

  it "should find the sitting requested" do
    HouseOfCommonsSitting.should_receive(:find_all_by_date).with("1999-02-08").and_return([@sitting])
    do_get
  end

  it "should assign the date of the section's sitting" do
    do_get
    assigns[:date].should_not be_nil
    assigns[:date].should == Date.new(1999, 2, 8)
  end

  it "should find the section using the slug" do
    @sitting.should_receive(:find_section_by_slug).and_return(@section)
    do_get
  end

  it "should assign the section for the view" do
    @sitting.should_receive(:find_section_by_slug).and_return(@section)
    do_get
    assigns[:section].should_not be_nil
    assigns[:section].should equal(@section)
  end

  it "should assign an empty marker options hash to the view" do
    do_get
    assigns[:marker_options].should == {}
  end
end

describe SectionsController do

  it_should_behave_like "All controllers"

  describe "#route_for" do
    it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons' } to /commons/1999/feb/08/test-slug" do
      params =  { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons' }
      route_for(params).should == "/commons/1999/feb/08/test-slug"
    end

    it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons', :format => 'xml' } to /commons/1999/feb/08/test-slug.js}" do
      params =  { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'commons', :format => 'js' }
      route_for(params).should == "/commons/1999/feb/08/test-slug.js"
    end

    it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'lords' } to /lords/1999/feb/08/test-slug" do
      params =  { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'lords' }
      route_for(params).should == "/lords/1999/feb/08/test-slug"
    end

    it "should map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'written_answers' } to /written_answers/1999/feb/08/test-slug" do
      params = {:controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'written_answers' }
      route_for(params).should == "/written_answers/1999/feb/08/test-slug"
    end

    it "should not map { :controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'fake_type' } to /fake_type/1999/feb/08/test-slug" do
      params = {:controller => 'sections', :action => 'show', :year => '1999', :month => 'feb', :day => '08', :id => 'test-slug', :type => 'fake_type' }
      lambda{ route_for(params).should == "/fake_type/1999/feb/08/test-slug" }.should raise_error(ActionController::RoutingError)
    end
  end

  describe 'when getting a section and slug ends_with "-"' do
    it 'should redirect to url for slug without "-" if section not found' do
      @sitting.stub!(:find_section_by_slug).and_return(nil)
      params = { :year => '1999', :month => 'feb', :day => '08', :id => "test-slug-", :type => "commons" }
      chomped_slug = 'test-slug'
      get :show, params
      response.code.should == '301'
      redirect_params = params.merge({:id=>chomped_slug})
      response.should redirect_to(redirect_params)
    end
  end

  describe "when stripping image tags" do
    before do
      @sitting = mock_model(HouseOfCommonsSitting)
      HouseOfCommonsSitting.stub!(:find_all_by_date).and_return([@sitting])
      @sitting.stub!(:all_sections).and_return(@sections)
      @section = mock_model(Section)
      @section.stub!(:title).and_return('Titl<lb/>e')
      @section.stub!(:title).and_return('Title')
      @sitting.stub!(:find_section_by_slug).and_return(@section)
    end

    def do_get
      get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "commons"
    end

    it 'should remove any image tags from the rendered page' do
      controller.should_receive(:strip_images)
      do_get
    end
  end

  describe "when getting a section by date and section slug" do
    before do
      @sitting = mock_model(HouseOfCommonsSitting)
      HouseOfCommonsSitting.stub!(:find_all_by_date).and_return([@sitting])
      @sitting.stub!(:all_sections).and_return(@sections)
      @section = mock_model(Section)
      @section.stub!(:title).and_return('Titl<lb/>e')
      @section.stub!(:title).and_return('Title')
      @sitting.stub!(:find_section_by_slug).and_return(@section)
    end

    def do_get
      get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "commons"
    end

    it_should_behave_like "handling GET /commons/1999/feb/08/test-slug with or without a format suffix"

    it "should render with the 'show' template" do
      do_get
      response.should render_template('show')
    end

    describe "and format is javascript" do
      before do
        @section.stub!(:to_json).and_return("some json content")
      end

      def do_get
        get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "commons", :format => 'js'
      end

      it_should_behave_like "handling GET /commons/1999/feb/08/test-slug with or without a format suffix"

      it 'should ask the section for its json' do
        @section.should_receive(:to_json)
        do_get
      end

      it 'should render the json with type header "text/x-json; charset=utf-8"' do
        do_get
        response.body.should == "some json content"
        response.headers["type"].should == "text/x-json; charset=utf-8"
      end
    end

    describe "and slug is a division number reference" do
      def do_get
        get :show, :year => '1999', :month => 'feb', :day => '08', :id => "division_1", :type => "commons"
      end

      it 'should call redirect_to_division method on DivisionsController' do
        @controller.should_receive(:redirect_to_division)
        do_get
      end
    end
  end

  describe 'when redirecting from short division url' do

    before do
      @division_number = 'division_2'
      @params = {
        :controller => 'sections', :type=>"lords",
        :year=>'1922', :month=>'may', :day=>'24', :id => @division_number}
      @sitting = mock('sitting')
    end

    it 'should get sitting based on date and type' do
      sitting = mock('sitting')

      Sitting.should_receive(:find_sitting).with('lords', Date.parse('1922-05-24')).and_return sitting
      @controller.should_receive(:redirect_to_division_if_found).with(sitting, @division_number)
      get :show, @params
    end

    it 'should return 404 status code if no sitting found' do
      Sitting.should_receive(:find_sitting).with('lords', Date.parse('1922-05-24')).and_return nil
      get :show, @params
      response.response_code.should == 404
    end

    describe 'and the division is recognized,' do
      before do
        @controller.should_receive(:with_sitting).and_yield(@sitting)
        division = mock('division', :section=> mock('section', :slug=>'section_slug') )
        @sitting.should_receive(:find_division).with(@division_number).and_return division
      end

      it 'should permanently redirect with status code 301 Moved Permanently' do
        section_slug = 'section_slug'
        get :show, @params
        response.response_code.should == 301
      end

      it 'should redirect to division url' do
        section_slug = 'section_slug'
        get :show, @params
        redirect_params = @params.merge({:id=>section_slug, :action => "show_division", :division_number=>@division_number, :controller=>'divisions'})
        response.should redirect_to(redirect_params)
      end
    end

    describe 'and the division is not recognized,' do
      before do
        @controller.should_receive(:with_sitting).and_yield(@sitting)
        @sitting.should_receive(:find_division).with(@division_number).and_return nil
      end

      it 'should temporarily redirect with status code 303 See Other' do
        get :show, @params
        response.response_code.should == 303
      end

      it 'should redirect to lords sitting url if type lords' do
        get :show, @params
        show_params = {
          :controller => 'lords', :action => 'show',
          :year=>'1922', :month=>'may', :day=>'24'}
        response.should redirect_to(show_params)
      end

      it 'should temporarily redirect to commons sitting url it type commons' do
        get :show, @params.merge({:type=>'commons'})
        show_params = {
          :controller => 'commons', :action => 'show',
          :year=>'1922', :month=>'may', :day=>'24'}
        response.should redirect_to(show_params)
      end
    end
  end

  describe "when getting a written answers section by date and section slug" do
    before do
      @sitting = mock_model(WrittenAnswersSitting)
      WrittenAnswersSitting.stub!(:find_all_by_date).and_return([@sitting])
      @sections = mock("sitting sections")
      @sitting.stub!(:all_sections).and_return(@sections)
      @section = mock_model(Section)
      @section.stub!(:title).and_return('Title')
      @section.stub!(:title).and_return('Title')
      @sitting.stub!(:find_section_by_slug).and_return(@section)
    end

    def do_get
      get :show, :year => '1999', :month => 'feb', :day => '08', :id => "test-slug", :type => "written_answers"
    end

    it 'should assign sitting in the view' do
      do_get
      assigns[:sitting].should_not be_nil
    end

    it "should find the sitting requested" do
      WrittenAnswersSitting.should_receive(:find_all_by_date).with("1999-02-08").and_return([@sitting])
      do_get
    end
  end
end
