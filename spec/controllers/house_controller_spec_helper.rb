
describe "controller that has routes correctly configured", :shared => true do

  it "should map { :controller => @house_type, :action => 'show', :year => '1999', :month => 'feb', :day => '08' } to /@house_type/1999/feb/02" do
    params = { :controller => @house_type, :action => 'show', :year => '1999', :month => 'feb', :day => '08' }
    route_for(params).should == "/#{@house_type}/1999/feb/08"
  end

  it "should map { :controller => @house_type, :action => 'show', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' } to /@house_type/1999/feb/02.xml" do
    params = { :controller => @house_type, :action => 'show', :year => '1999', :month => 'feb', :day => '08', :format => 'xml' }
    route_for(params).should == "/#{@house_type}/1999/feb/08.xml"
  end

  it "should map { :controller => @house_type, :action => 'index', :year => '1999', :month => 'feb' } to /@house_type/1999/feb" do
    params = { :controller => @house_type, :action => 'index', :year => '1999', :month => 'feb' }
    route_for(params).should == "/#{@house_type}/1999/feb"
  end

  it "should map { :controller => @house_type, :action => 'index', :year => '1999' } to /@house_type/1999" do
    params = { :controller => @house_type, :action => 'index', :year => '1999' }
    route_for(params).should == "/#{@house_type}/1999"
  end

  it "should map { :controller => @house_type, :action => 'index', :decade => '1990s' } to /@house_type/1990s" do
    params = { :controller => @house_type, :action => 'index', :decade => '1990s' }
    route_for(params).should == "/#{@house_type}/1990s"
  end
  
  it "should map { :controller => @house_type, :action => 'index', :century => 'C20' } to /@house_type/C20" do
    params = { :controller => @house_type, :action => 'index', :century => 'C20' }
    route_for(params).should == "/#{@house_type}/C20"
  end
  
end

describe "controller that isn't mapping the root url", :shared => true do

  it "should map { :controller => @house_type, :action => 'index' } to /@house_type" do
    params = { :controller => @house_type, :action => 'index'}
    route_for(params).should == "/#{@house_type}"
  end

end

describe " handling GET /<house_type>", :shared => true do

  before do
    @sitting = mock_model(@sitting_model)
  end

  def do_get
    get :index
  end

  it 'should set the sitting model correctly' do
    @controller.send(:model).should == @sitting_model
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it 'should not assign section to the view' do
    do_get
    assigns[:section].should be_nil
  end

  it 'should assign FIRST_DATE to the view as @date' do
    do_get
    assigns[:date].should == FIRST_DATE
  end

  it 'should set the timeline resolution to the next resolution up from the page resolution' do
    Date.should_receive(:higher_resolution).with(nil).and_return('higher resolution')
    do_get
    assigns[:timeline_resolution].should == 'higher resolution'
  end

  it 'should assign the sitting type to the view' do
    do_get
    assigns[:sitting_type].should == @sitting_model
  end

  it "should render with the 'sittings/index' template" do
    do_get
    response.should render_template('sittings/index')
  end

end

describe " handling GET /<house_type>/1999", :shared => true do

  before do
    @controller.should_not_receive(:make_map)
    @sitting = mock_model(@sitting_model)
    @sitting_model.stub!(:find_in_resolution).and_return([@sitting])
  end

  def do_get
    get :index, :year => '1999'
  end

  it 'should set the sitting model correctly' do
    @controller.send(:model).should == @sitting_model
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it 'should not assign section to the view' do
    do_get
    assigns[:section].should be_nil
  end

  it 'should not assign LAST_DATE to the view as @date' do
    do_get
    assigns[:date].should_not == LAST_DATE
  end

  it 'should set the timeline resolution to the next resolution up from the page resolution' do
    Date.should_receive(:higher_resolution).with(:year).and_return('higher resolution')
    do_get
    assigns[:timeline_resolution].should == 'higher resolution'
  end

  it 'should assign the sitting type to the view' do
    do_get
    assigns[:sitting_type].should == @sitting_model
  end

  it "should render with the 'sittings/index' template" do
    do_get
    response.should render_template('sittings/index')
  end

end

describe " handling GET /<house_type>/1999/feb", :shared => true do

  before do
    @controller.should_not_receive(:make_map)
    @sitting = mock_model(@sitting_model)
    @sitting_model.stub!(:find_in_resolution).and_return([@sitting])
  end

  def do_get
    get :index, :year => '1999', :month => 'feb'
  end
  it 'should set the sitting model correctly' do
    @controller.send(:model).should == @sitting_model
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it 'should not assign section to the view' do
    do_get
    assigns[:section].should be_nil
  end

  it 'should not assign LAST_DATE to the view as @date' do
    do_get
    assigns[:date].should_not == LAST_DATE
  end

  it 'should set the timeline resolution to the next resolution up from the page resolution' do
    Date.should_receive(:higher_resolution).with(:month).and_return('higher resolution')
    do_get
    assigns[:timeline_resolution].should == 'higher resolution'
  end

  it 'should assign the sitting type to the view' do
    do_get
    assigns[:sitting_type].should == @sitting_model
  end

  it "should render with the 'sittings/index' template" do
    do_get
    response.should render_template('sittings/index')
  end

end

describe " handling GET /<house_type>/1999/feb/08", :shared => true do

  before do
    @controller.should_not_receive(:make_map)
    @sitting = mock_model(@sitting_model)
    @sitting_model.stub!(:find_in_resolution).and_return([@sitting])
  end

  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08'
  end

  it 'should not assign section in the view' do
    do_get
    assigns[:section].should be_nil
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should look for sittings on the date passed" do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 2, 8), :day).and_return([@sitting])
    do_get
  end

  it 'should ask for the sittings sorted by sitting type' do
    Sitting.should_receive(:sort_by_type)
    do_get
  end

  it "should render with the 'show' template " do
    do_get
    response.should render_template('sittings/show')
  end

  it "should assign day to true" do
    do_get
    assigns[:day].should be_true
  end

  it "should assign date based on date in URL" do
    do_get
    assigns[:date].should == Date.new(1999, 2, 8)
  end

  it "should assign date resolution based on date in URL" do
    do_get
    assigns[:resolution].should == :day
  end

  it "should assign the sittings to the view" do
    do_get
    assigns[:sittings].should == [@sitting]
  end

  it "should assign an empty marker options hash to the view" do
    do_get
    assigns[:marker_options].should == {}
  end
  
  it 'should remove any image tags from the rendered page' do
    controller.should_receive(:strip_images)
    do_get
  end

end

describe " handling GET /<house_type>/1999/feb/08.opml", :shared => true do
  before do
    @controller.should_not_receive(:make_map)
    @sitting = mock_model(@sitting_model)
    @sitting_model.stub!(:find_in_resolution).and_return([@sitting])
  end

  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :format => 'opml'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should find the sitting requested" do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 2, 8), :day).and_return([@sitting])
    do_get
  end
  
  it "should render with the show.opml template" do
    do_get
    response.should render_template('sittings/show.opml.haml')
  end
  
end

describe " handling GET /<house_type>/1999/feb/08.xml", :shared => true do

  before do
    @controller.should_not_receive(:make_map)
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
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 2, 8), :day).and_return([@sitting])
    do_get
  end

  it "should call the ask the sitting for it's xml" do
    @sitting.should_receive(:to_xml)
    do_get
  end

end

describe " handling GET /<house_type>/1999/feb/08.js", :shared => true do

  before do
    @sitting = mock_model(@sitting_model)
    @sitting.stub!(:to_json)
    @sitting_model.stub!(:find_in_resolution).and_return([@sitting])
  end

  def do_get
    get :show, :year => '1999', :month => 'feb', :day => '08', :format => 'json'
  end

  it "should be successful" do
    do_get
    response.should be_success
  end

  it "should find the sitting requested" do
    @sitting_model.should_receive(:find_in_resolution).with(Date.new(1999, 2, 8), :day).and_return([@sitting])
    do_get
  end

  it "should ask the sitting for it's json" do
    @sitting.should_receive(:to_json)
    do_get
  end

end