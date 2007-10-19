require File.dirname(__FILE__) + '/../spec_helper'

describe SearchController do

  before do
    @mock_results = mock("search results")
    @mock_results.stub!(:facets).and_return({"facet_fields" => []})
    @mock_results.stub!(:total_hits)
    Contribution.stub!(:find_by_solr).and_return(@mock_results)
  end
  
  def do_get
    get 'index', :page => "2", :query => "test query"
  end
  
  it "should return index page" do
    do_get
    response.should be_success
  end
  
  it "should set the offset for solr to 10 for the second page of results" do
    do_get
    @controller.send(:pagination_options).should == { :offset => 10 }
  end
  
  
end
