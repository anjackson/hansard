describe "All controllers", :shared => true do

  def setup_rewriting
    @request = ActionController::TestRequest.new
    @controller.request = @request
    @controller.instance_variable_set(:@url,
    (ActionController::UrlRewriter.new @request, {}))
  end

  def create_section sitting_model
    section = mock_model(Section)
    section.stub!(:sitting).and_return(sitting_model.new(:date => Date.new(1957, 6, 25)))
    section.stub!(:id_hash).and_return({
      :id    => "exports-to-israel",
      :year  => '1957',
      :month => 'jun',
      :day   => '25',
      :type  => sitting_model.uri_component})
    section
  end

  def expect_section_url model, url
    setup_rewriting
    section = create_section model
    @controller.section_url(section).should == url
  end

  def expect_section_path model, path
    setup_rewriting
    section = create_section model
    @controller.section_path(section).should == path
  end
  
  it "should create a url like http://test.host/commons/1957/jun/25/exports-to-israel for a section from the commons on the day shown with the slug shown" do
    expect_section_url HouseOfCommonsSitting, "http://test.host/commons/1957/jun/25/exports-to-israel"
  end

  it "should create a url like http://test.host/lords/1957/jun/25/exports-to-israel for a section from the lords on the day shown with the slug shown" do
    expect_section_url HouseOfLordsSitting,  "http://test.host/lords/1957/jun/25/exports-to-israel"
  end

  it "should create a url like http://test.host/written_answers/1957/jun/25/exports-to-israel for a section from a commons written answer on the day shown with the slug shown" do
    expect_section_url CommonsWrittenAnswersSitting, "http://test.host/written_answers/1957/jun/25/exports-to-israel"
  end

  it "should create a url like http://test.host/lords_reports/1957/jun/25/exports-to-israel for a section from a written answer on the day shown with the slug shown" do
    expect_section_url HouseOfLordsReport,  "http://test.host/lords_reports/1957/jun/25/exports-to-israel"
  end

  it 'should create a path like /commons/1957/jun/25/exports-to-israel for a section from the commons on one day with the slug shown' do
    expect_section_path HouseOfCommonsSitting, "/commons/1957/jun/25/exports-to-israel"
  end

  it "should create a path like /lords/1957/jun/25/exports-to-israel for a section from the lords on the day shown with the slug shown" do
    expect_section_path HouseOfLordsSitting,  "/lords/1957/jun/25/exports-to-israel"
  end

  it "should create a path like /written_answers/1957/jun/25/exports-to-israel for a section from a commons written answer on the day shown with the slug shown" do
    expect_section_path CommonsWrittenAnswersSitting, "/written_answers/1957/jun/25/exports-to-israel"
  end

  it "should create a path like /lords_reports/1957/jun/25/exports-to-israel for a section from a written answer on the day shown with the slug shown" do
    expect_section_path HouseOfLordsReport,  "/lords_reports/1957/jun/25/exports-to-israel"
  end

  it 'should ask the sitting class for a normalized column when creating a column url' do
    setup_rewriting
    section = create_section CommonsWrittenAnswersSitting
    CommonsWrittenAnswersSitting.should_receive(:normalized_column).with("45").and_return("")
    @controller.column_url("45", section)
  end

  it 'should create a url like "/written_answers/1957/jun/25/exports-to-israel#column_45w" for a section and column' do
    setup_rewriting
    section = create_section CommonsWrittenAnswersSitting
    @controller.column_url("45", section).should == "http://test.host/written_answers/1957/jun/25/exports-to-israel#column_45w"
  end

end

describe 'A controller with alphabetical index links', :shared => true do

  before do
    name_method = @name_method || :name
    @a_model = mock(@model, name_method => "apple")
    @b_model = mock(@model, name_method => "banana")
    @c_model = mock(@model, name_method => "Wildlife and Countryside\nAct")
    @models = [@a_model, @b_model, @c_model]
  end

  it "should map { :controller => @controller, :action => 'index', :letter => 'b' } to /@controller/b" do
    params = { :controller => @controller_name, :action => 'index', :letter => 'b'}
    route_for(params).should == "/#{@controller_name}/b"
  end

  it 'should ask for all sorted models and assign them to the view' do
    @model.should_receive(:find_all_sorted).and_return(@models)
    get :index
    assigns[@controller_name.to_sym].should == @models
  end

  it 'should assign a list of models starting with "A" to the view if not passed a letter param' do
    @model.stub!(:find_all_sorted).and_return(@models)
    get :index
    assigns["list_#{@controller_name}".to_sym].should == [@a_model]
  end

  it 'should assign a list of models starting with a letter to the view if passed a letter param' do
    @model.stub!(:find_all_sorted).and_return(@models)
    get :index, :letter => 'b'
    assigns["list_#{@controller_name}".to_sym].should == [@b_model]
  end

  it 'should redirect uppercase letter to the lower case letter url' do
    @model.stub!(:find_all_sorted).and_return(@models)
    get :index, :letter => 'B'
    params = { :controller => @controller_name, :action => 'index', :letter => 'b'}
    response.should redirect_to(params)
  end
end
