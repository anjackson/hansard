require File.dirname(__FILE__) + '/../spec_helper'

describe SearchController, " in general" do
  it_should_behave_like "All controllers"
end

describe SearchController, " when routing requests " do

  it "should map { :controller => 'search', :action => 'show', :query => 'test' } to /search/test" do
    params = { :controller => 'search', :action => 'show', :query => 'test' }
    route_for(params).should == "/search/test"
  end
  
  it 'should map /search/test.atom to { :controller => "search", :action => "show", :query => "test", :format => "atom"}' do 
    params = { :controller => 'search', :action => 'show', :query => 'test', :format => 'atom' }
    params_from(:get, "/search/test.atom").should == params
  end

end

describe SearchController, "when asked for results in atom format" do 
  
  before do 
    Contribution.stub!(:find_by_solr)
    @search = mock_model(Search, :null_object => true,
                                 :hansard_reference => nil,
                                 :get_results => nil, 
                                 :page => 1, 
                                 :num_per_page => 10)
    Search.stub!(:new).and_return(@search)
  end
  
  def do_get
    get 'show', :query => 'test query', :format => 'atom'
  end
  
  it 'should be successful' do 
    do_get
    response.should be_success
  end
  
  it 'should render with the "show.atom.builder" template' do 
    do_get
    response.should render_template('search/show.atom.builder')
  end
  
  it 'should log an error and render with the "query_error.atom.builder template" if there is a search error' do 
    @search.stub!(:get_results).and_raise(SearchException)
    @controller.logger.should_receive(:error).with('Solr error: SearchException')
    do_get
    response.should render_template('search/query_error.atom.builder')
  end 
  
end

describe SearchController do

  before do
    @mock_results = mock("search results")
    @search = mock_model(Search, :null_object => true,
                                 :hansard_reference => nil,
                                 :get_results => @mock_results)
    Search.stub!(:new).and_return(@search)
    WillPaginate::Collection.stub!(:new)
  end

  def do_get
    get 'show', :page => "2", :query => "test query"
  end

  it "should be successful" do
    do_get
    response.should be_success
  end
  
   it 'should show the index template if no search terms are passed' do
    @controller.expect_render.with(:template => "search/index")
    get 'show'
  end

  it 'should ignore any sort param that isn\'t "date" or "reverse_date"' do
    @controller.send(:get_search_params, {:sort => "mooo"})[:sort].should be_nil
    @controller.send(:get_search_params, {:sort => "date"})[:sort].should == 'date'
    @controller.send(:get_search_params, {:sort => "reverse_date"})[:sort].should == 'reverse_date'
  end

  it 'should ignore any decade param that isn\'t four digits followed by an \'s\'' do
    @controller.send(:get_search_params, {:decade => 'moo'})[:decade].should be_nil
    @controller.send(:get_search_params, {:decade => '1950s'})[:decade].should == '1950s'
  end
  
  it 'should ignore any century param that isn\'t a "C" followed by two digits' do
    @controller.send(:get_search_params, {:century => 'moo'})[:century].should be_nil
    @controller.send(:get_search_params, {:century => 'C19'})[:century].should == 'C19'
  end

  it 'should log a message and redirect to the query error page if a search exception occurs when finding results' do
    @search.stub!(:get_results).and_raise(SearchException)
    @controller.logger.should_receive(:error).with('Solr error: SearchException')
    do_get
    response.should render_template('search/query_error')
  end

  it 'should redirect a post request with a query param in order to produce a get request to the query results url' do
    post 'show', :query => 'test'
    response.should redirect_to('/search/test')
  end
  
  it 'should set up pagination for the results' do 
    WillPaginate::Collection.should_receive(:new)
    do_get
  end

end

describe SearchController, 'when query text is a hansard reference' do

  def return_reference(sections, column)
    reference = mock(HansardReference, :find_sections => sections, :column => column)
    HansardReference.stub!(:create_from).and_return(reference)
  end
  
  it 'should ask for the hansard column url using the column and section from the hansard reference' do
    column = 4
    section = mock(Section, :sitting => mock_model(Sitting))
    return_reference([section], column)
    @controller.should_receive(:column_url).with(column, section).and_return('')
    get 'show', :query => 'some query'
  end
    
  it 'should redirect a get request to the column url of the first section matching the reference' do
    column_url = '/the column url'
    section = mock_model(Section)
    return_reference([section, mock_model(Section)], "305")
    @controller.stub!(:column_url).with("305", section).and_return(column_url)
    get 'show', :query => 'some query'
    response.should redirect_to(column_url)
  end

  it 'should redirect a get request to the "reference not found" view if not section matching the reference is found' do
    return_reference([], nil)
    get 'show', :query => 'some query'
    response.should render_template('search/reference_not_found')
  end

end

