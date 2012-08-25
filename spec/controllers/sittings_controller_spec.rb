require File.dirname(__FILE__) + '/../spec_helper'

describe SittingsController do 
  
  describe " in general" do
  
    it_should_behave_like "All controllers"
  
  end

  describe "#route_for" do

    before(:each) do
      @house_type = 'sittings'
    end

    it "should map { :controller => @house_type, :action => 'index' } to /" do
      params = { :controller => @house_type, :action => 'index', :home_page => true}
      route_for(params).should == "/"
    end
  
    it "should map { :controller => 'sittings', :action => 'feed', :years => 10, :format => 'atom' } to /years-ago/10" do 
      params = { :controller => 'sittings', :action => 'feed', :years => 10, :format => 'atom' } 
      route_for(params).should == '/years-ago/10.atom'
    end 

    it_should_behave_like "controller that has routes correctly configured"

  end

  describe " handling dates" do

    it_should_behave_like "a date-based controller"

  end

  describe " handling GET /sittings" do

    before(:all) do
      @sitting_model = Sitting
    end

    it_should_behave_like " handling GET /<house_type>"

  end

  describe " handling GET /sittings/1999" do

    before(:all) do
      @sitting_model = Sitting
    end

    def do_get
      get :show, :year => '1999'
    end

    it_should_behave_like " handling GET /<house_type>/1999"

  end

  describe " handling GET /sittings/1999/feb" do

    before(:all) do
      @sitting_model = Sitting
    end

    it_should_behave_like " handling GET /<house_type>/1999/feb"

  end

  describe "handling GET /sittings/1999/feb/08" do

    before(:all) do
      @sitting_model = Sitting
    end

    it_should_behave_like " handling GET /<house_type>/1999/feb/08"

  end

  describe " handling GET /sittings/1999/feb/08.opml" do
  
    before(:all) do
      @sitting_model = Sitting
    end

    it_should_behave_like " handling GET /<house_type>/1999/feb/08.opml"
  
  end
  
  describe 'handling GET /years-ago/10.xml' do
    
    before do 
      Sitting.stub!(:sections_from_years_ago).and_return([])
    end
    
    def do_get(years='10')
      get :feed, :years => years, :format => 'xml'
    end
    
    it 'should ask for the sections from 10 years ago for the last 10 days' do
      Sitting.should_receive(:sections_from_years_ago).with(10, Date.today, 10).and_return([])
      do_get
    end 
    
    it 'should render a feed section for each returned item' do
      first_item = mock('first item')
      second_item = mock('second item')
      Sitting.stub!(:sections_from_years_ago).and_return([first_item, second_item])
      controller.should_receive(:render_feed_section).with(first_item)
      controller.should_receive(:render_feed_section).with(second_item)     
      do_get 
    end
    
    it 'should render with the "years_ago.atom.builder" template' do 
      do_get
      response.should render_template('sittings/years_ago.atom.builder')
    end
    
    it 'should render a 404 response if the requested feed is not a default feed' do 
      do_get(12)
      response.response_code.should == 404
    end
  
  end
  
  describe 'when rendering an item for display in a feed' do
    
    before do 
      @sitting = mock_model(Sitting)
      @section = mock_model(Section, :sitting => @sitting)
      @date = Date.new(1992, 1, 1)
      @item = [@section, @date]
      controller.stub!(:render_to_string).and_return('test content')
    end
    
    it 'should ask for the section\'s sitting' do
      @section.should_receive(:sitting).and_return(@sitting)
      controller.send(:render_feed_section, @item)
    end 
    
    it 'should render the sections/show template to a string' do 
      controller.should_receive(:render_to_string).with(:template => 'sections/show.haml')
      controller.send(:render_feed_section, @item)
    end
    
    it 'should return the section, date and content produced by rendering the template' do 
      controller.send(:render_feed_section, @item).should == [@section, @date, 'test content']
    end
    
  end
end
