require File.dirname(__FILE__) + '/../spec_helper'

describe SearchController do

  before do
    @mock_results = mock("search results")
    @mock_results.stub!(:facets).and_return({"facet_fields" => []})
    Contribution.stub!(:find_by_solr).and_return(@mock_results)
  end
  
  it "should return index page" do
    get 'index'
    response.should be_success
  end
  
end
