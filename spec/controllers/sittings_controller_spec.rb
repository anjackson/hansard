require File.dirname(__FILE__) + '/house_controller_spec_helper'

describe SittingsController, "#route_for" do

  before(:each) do
    @house_type = 'sittings'
  end

  it "should map { :controller => @house_type, :action => 'index' } to /" do
    params = { :controller => @house_type, :action => 'index'}
    route_for(params).should == "/"
  end
  
  it 'should map { :controller => "sittings", :action => "show", :decade => "1940s"} to /sittings/1940s' do
    params = { :controller => "sittings", :action => "show", :decade => "1940s" }
    route_for(params).should == "/sittings/1940s"
  end
  
  it_should_behave_like "controller that has routes correctly configured"

end

describe SittingsController, " handling dates" do

  it_should_behave_like "a date-based controller"

end

describe SittingsController, " handling GET /sittings" do

  before(:all) do
    @sitting_model = Sitting
  end

  def do_get
    get :index
  end

  it_should_behave_like " handling GET /<house_type>"
  
  it 'should assign LAST_DATE to the view as @date' do
    do_get
    assigns[:date].should == LAST_DATE
  end
  
  it 'should set the timeline resolution to the next lower resolution from the page resolution' do
    @controller.should_receive(:lower_resolution).with(nil).and_return('lower resolution')
    do_get
    assigns[:timeline_resolution].should == 'lower resolution'
  end

end

describe SittingsController, " handling GET /sittings/1999" do

  before(:all) do
    @sitting_model = Sitting
  end

  def do_get
    get :show, :year => '1999'
  end

  it_should_behave_like " handling GET /<house_type>/1999"

  it 'should set the timeline resolution to the next lower resolution from the page resolution' do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 1, 1), :year).and_return([@sitting, @sitting])
    @controller.should_receive(:lower_resolution).with(:year).and_return('lower resolution')
    do_get
    assigns[:timeline_resolution].should == 'lower resolution'
  end
  
end

describe SittingsController, " handling GET /sittings/1999/feb" do

  before(:all) do
    @sitting_model = Sitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb"

end

describe SittingsController, "handling GET /sittings/1999/feb/08" do

  before(:all) do
    @sitting_model = Sitting
  end

  it_should_behave_like " handling GET /<house_type>/1999/feb/08"
  
end


describe SittingsController, " handling GET /sittings/source/1999/feb/08.xml" do

  before(:all) do
    @sitting_model = Sitting
  end

  it_should_behave_like " handling GET /<house_type>/source/1999/feb/08.xml"

end

