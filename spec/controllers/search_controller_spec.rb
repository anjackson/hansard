require File.dirname(__FILE__) + '/../spec_helper'

describe SearchController do

  before do
    @mock_results = mock("search results")
    @mock_results.stub!(:facets).and_return({"facet_fields" => []})
    @mock_results.stub!(:total_hits)
    Contribution.stub!(:find_by_solr).and_return(@mock_results)
  end
  
  def do_get
    get 'show', :page => "2", :query => "test query"
  end
  
  it "should be successful" do
    do_get
    response.should be_success
  end
  
  it "should set the limit for solr to 30" do
    do_get
    @controller.send(:pagination_options)[:limit].should == 30
  end
  
  it "should set the offset for solr to 30 for the second page of results" do
    do_get
    @controller.send(:pagination_options)[:offset].should == 30 
  end
  
  it 'should redirect back to the previous page if no search terms are passed' do
    @controller.should_receive(:redirect_to).with(:back)
    get 'show', :query => ''
  end
  
  it 'should ignore any sort param that isn\'t "date"' do
    get 'show', :query => 'test', :sort => 'mooo'
    assigns[:sort].should be_nil
    get 'show', :query => 'test', :sort => 'date'
    assigns[:sort].should == 'date'
  end
  
  it 'should ignore any decade param that isn\'t four digits followed by an \'s\'' do
    get 'show', :query => 'test', :decade => 'mooo'
    assigns[:decade].should be_nil
    get 'show', :query => 'test', :decade => '1950s' 
    assigns[:decade].should == '1950s'
  end
  
  it 'should redirect to the query error page if a solr exception occurs when finding results' do
    Contribution.stub!(:find_by_solr).and_raise(RuntimeError)
    do_get
    response.should render_template('search/query_error')
  end
  
end
