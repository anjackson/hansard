require File.dirname(__FILE__) + '/../spec_helper'

describe Search, " when created" do

  it 'should look a date match if it has a query' do 
    DateParser.stub!(:date_match).and_return("date match")
    search = Search.new(:query => 'query')
    search.date_match.should == 'date match'
  end
  
  it 'should look for 5 people matches if it has a query' do 
    Person.stub!(:find_partial_matches).with('query', 5).and_return("people matches")
    search = Search.new(:query => 'query')
    search.speaker_matches.should == 'people matches'
  end
  
  it 'should set the search string if it has a query' do
    search = Search.new(:query => 'query')
    search.search_string.should_not be_nil
  end
  
  it 'should set the start date to the first date for which we have data' do
    search = Search.new({:query => 'query'}) 
    search.start_date.should == FIRST_DATE
  end
  
end

describe Search, " when handling search options" do
  
  before do 
    @search = Search.new({:query => 'test'})
  end
  
  it 'should set the number of results per page to 10 if no value is passed to it' do
    @search.parse_options(:query => 'my query')
    @search.num_per_page.should == 10
  end

  it 'should set the number of results per page to the value passed in the options' do
    @search.parse_options(:num_per_page => 50, :query => 'my query')
    @search.num_per_page.should == 50
  end
  
  it 'should set the page for the search to 1 when none is specified' do 
    @search.parse_options(:query => 'my query')
    @search.page.should == 1
  end
  
  it 'should set the page for the search to the value passed in the options' do 
    @search.parse_options(:page => 4, :query => 'my query')
    @search.page.should == 4
  end
  
  it 'should set the query to the value passed in the options' do 
    @search.parse_options(:query => 'my query')
    @search.query.should == 'my query'
  end
  
  it 'should set the sitting type to the value passed in the options' do 
    @search.parse_options(:type => 'my type', :query => 'my query')
    @search.sitting_type.should == 'my type'
  end
    
  it 'should ask for the person associated with a slug if one is passed to it' do
    Person.should_receive(:find_by_slug).with('person-slug')
    @search.parse_options(:query => 'query', :speaker => 'person-slug')
  end

  it 'should set its speaker to the person returned' do 
    Person.stub!(:find_by_slug).and_return("person")
    @search.parse_options(:query => 'query', :speaker => 'person-slug')
    @search.speaker.should == "person"
  end

end

describe Search, ' when cleaning a query' do 

  before do 
    @search = Search.new({:query => 'query'})
  end
  
  it 'should strip HTML tags from the query' do 
    @search.clean_query("<i>moo</i>").should == 'moo'
  end
  
  it 'should strip a single double quote from the query' do 
    @search.clean_query('"test').should == 'test'
  end
  
  it 'should not strip a pair of double quotes from the query' do 
    @search.clean_query('"test"').should == '"test"'
  end

end

describe Search, " when creating a search string" do 

  before do 
    @search = Search.new({:query => 'query'})
  end
  
  it 'should return "solr_text:query AND person_id:"1"" if a person with id 1 is set' do 
    @search.speaker = mock_model(Person, :id => 1)
    @search.create_search_string
    @search.search_string.should == "solr_text:query AND person_id:\"1\""
  end
  
  it 'should return "solr_text:query AND sitting_type:"Commons"" if a sitting_type of "Commons" is set' do 
    @search.sitting_type = "Commons"
    @search.create_search_string
    @search.search_string.should == 'solr_text:query AND sitting_type:"Commons"'
  end 
  
  it 'should return "solr_text:query AND date:[2004-03-12 TO 2005-01-11]" if a resolution, start and end dates are set' do 
    @search.resolution = :decade
    @search.start_date = Date.new(2004, 3, 12)
    @search.end_date = Date.new(2005, 1, 11)
    @search.create_search_string
    @search.search_string.should == "solr_text:query AND date:[2004-03-12 TO 2005-01-11]"
  end
  
  it 'should return "solr_text:query AND person_id:\"1\" AND sitting_type:\"Commons\" AND date:[2004-03-12 TO 2005-01-11]" when date, person and type params are set' do 
    @search.resolution = :decade
    @search.start_date = Date.new(2004, 3, 12)
    @search.end_date = Date.new(2005, 1, 11)
    @search.sitting_type = "Commons"
    @search.speaker = mock_model(Person, :id => 1)
    @search.create_search_string
    @search.search_string.should == "solr_text:query AND person_id:\"1\" AND sitting_type:\"Commons\" AND date:[2004-03-12 TO 2005-01-11]"
  end
   
  it 'should return "solr_text:query" if none of the other attributes are set' do 
    @search.create_search_string
    @search.search_string.should == "solr_text:query"
  end
  
end
 
describe Search, ' when getting a time interval from the options' do 

  before do 
    @search = Search.new(:query => 'test query')
  end
  
  it 'should set resolution to :decade if the options hash has a decade key' do 
    @search.time_interval(:decade => '1950s')
    @search.resolution.should == :decade
  end
  
  it 'should return the decade value if the options hash has a decade key' do 
    @search.time_interval(:decade => '1950s').should == '1950s'
  end
  
  it 'should set resolution to :decade if the options hash has a year key' do 
    @search.time_interval(:year => 1950)
    @search.resolution.should == :year
  end
  
  it 'should return the decade value if the options hash has a year key' do 
    @search.time_interval(:year => 1950).should == 1950
  end
  
  it 'should set resolution to :decade if the options hash has a month key' do 
    @search.time_interval(:month => '1940-11')
    @search.resolution.should == :month
  end
  
  it 'should return the decade value if the options hash has a month key' do 
    @search.time_interval(:month => '1940-11').should == '1940-11'
  end
  
  it 'should set resolution to :decade if the options hash has a day key' do 
    @search.time_interval(:day => '1940-11-21')
    @search.resolution.should == :day
  end
  
  it 'should return the decade value if the options hash has a day key' do 
    @search.time_interval(:day => '1940-11-21').should == '1940-11-21'
  end
  
end
 
describe Search, ' when setting start and end dates on a search from a time interval' do
  
  before do 
    @search = Search.new({:query => 'query'})
  end
  
  def expect_interval(date_value, resolution, start_date, end_date)
    @search.resolution = resolution
    @search.set_interval(date_value)
    @search.start_date.should == start_date
    @search.end_date.should == end_date
  end
  
  it 'should set the start date to 1 Jan 1900 and end date to 31 Dec 1999 if the resolution is set to century and date value is "C20"' do 
    expect_interval('C20', :century, Date.new(1900, 1, 1), Date.new(1999, 12, 31))
  end
  
  it 'should set the start date to 1 Jan 1980 and end date to 31 Dec 1989 if its resolution is set to decade and date value is "1980s"' do 
    expect_interval("1980s", :decade, Date.new(1980, 1, 1), Date.new(1989, 12, 31)) 
  end
  
  it 'should set the start date to 1 Jan 1981 and the end date to 31 Dec 1981 if its resolution is set to year and date value is "1981"' do
    expect_interval("1981", :year, Date.new(1981, 1, 1), Date.new(1981, 12, 31)) 
  end
  
  it 'should set the start date to 1 Nov 1981 and the end date to 30 Nov 1981 if the resolution is set to month and date value is "1981-11"' do
    expect_interval('1981-11', :month, Date.new(1981, 11, 1), Date.new(1981, 11, 30))
  end

  it 'should set the start date to 11 Nov 1981 and end date to 11 Nov 1981 if the resolution is set to day and date value is "1981-11-11"' do 
    expect_interval('1981-11-11', :day, Date.new(1981, 11, 11), Date.new(1981, 11, 11))
  end
  
end

describe Search, " when creating search options" do 
  
  before do 
    @search = Search.new(:query => 'query')
  end
  
  it 'should include pagination options and highlighting options' do 
    @search.stub!(:highlight_options).and_return(:highlight => true)
    @search.stub!(:pagination_options).and_return(:pagination => true)
    @search.search_options[:pagination].should be_true
    @search.search_options[:highlight].should be_true
  end
  
  it 'should include sort options if a sort option is set' do 
    @search.stub!(:sort_options).and_return(:sort => true)
    @search.sort = "date"
    @search.search_options[:sort].should be_true
  end
  
  it 'should include facet options if the search requires facets' do 
    @search.stub!(:facet_options).and_return(:facet => true)
    @search.search_options[:facet].should be_true
  end

  it 'should set the limit for the search to 50 when the number of results per page is set to 50' do
    @search.parse_options(:num_per_page => 50, :query => 'my query')
    @search.search_options[:limit].should == 50
  end
  
  it 'should set the offset for the search to zero for the first page' do 
    @search.page = 1
    @search.search_options[:offset].should == 0
  end

  it 'should set the offset for the search to 10 for the second page' do
    @search.page = 2
    @search.search_options[:offset].should == 10
  end
    
  it 'should set the order for the search to "date asc" if a date sort is requested' do
    search = Search.new(:sort => 'date', :num_per_page => 30, :query => 'query')
    search.search_options[:order].should == 'date asc'
  end
  
  it 'should set the order for the search to "date desc" if a reverse date sort is requested' do 
    search = Search.new(:sort => 'reverse_date', :num_per_page => 30, :query => 'query')
    search.search_options[:order].should == 'date desc'
  end
  
end

describe Search, " when getting results" do 
  
  it 'should ask for contributions matching the search string and search options' do 
    search = Search.new(:query => 'query')
    Contribution.should_receive(:find_by_solr).with(search.search_string, search.search_options).and_return(mock("search results", :null_object => true))
    search.get_results
  end
  
end

describe SearchController, ' when getting facets' do 

  def there_should_be_no_facets(result_set)
    search = Search.new(:query => 'query')
    search.send(:get_facets, result_set, "test_facet").should be_nil
  end
  
  def there_should_be_facets(result_set)
    search = Search.new(:query => 'query')
    search.send(:get_facets, result_set, "test_facet").should_not be_nil
  end
  
  it 'should return false for a query result set with no facets' do
    result_set = mock("result_set", :facets => nil)
    there_should_be_no_facets result_set
  end

  it 'should return false for a query result set with no facet fields' do
    result_set = mock("result_set", :facets => {})
    there_should_be_no_facets result_set
  end
  
  it 'should return false for a query result set with no facet fields' do
    result_set = mock("result_set", :facets => {"facet_fields" => {}})
    there_should_be_no_facets result_set
  end
  
  it 'should return true for a query result with the named facet field and a value' do 
    result_set = mock('result_set', :facets => {"facet_fields" => {"test_facet" => ['value']}})
    there_should_be_facets result_set
  end

end

describe SearchController, ' when getting date facets' do
  
  before do 
    @search = Search.new(:query => 'query')
    @result_set = mock('result set')
    @date_facets = { "1928-06-18" => 1,
                    "1986-01-15" => 15,
                    "1998-10-08" => 7,
                    "1982-11-17" => 9,
                    "1986-10-16" => 10,
                    "2004-07-21" => 13 }
  end
  
  it 'should return an empty hash if there are no date facets in the result set' do 
    @search.stub!(:get_facets).with(@result_set, "date_facet").and_return(nil)
    @search.send(:create_date_facets, @result_set).should == {}
  end

  it 'should return a hash with keys that are dates, and values that are integer counts for a query' do

    @search.stub!(:get_facets).and_return(@date_facets)
    expected = { Date.new(1928, 6, 18) => 1,
                 Date.new(1986, 1, 15) => 15,
                 Date.new(1998, 10, 8) => 7,
                 Date.new(1982, 11, 17) => 9,
                 Date.new(1986, 10, 16) => 10,
                 Date.new(2004, 7, 21) => 13 }
    @search.send(:create_date_facets, @result_set).should == expected
  end

  it 'should set a timeline anchor of the first day in the most common century in the search results' do 
    @search.stub!(:get_facets).and_return(@date_facets)
    @search.send(:create_date_facets, @result_set)
    @search.timeline_anchor.should == Date.new(1900, 1, 1)
  end
  
  it 'should not set a timeline anchor if the search has a date resolution' do 
    @search.stub!(:resolution).and_return(:decade)
    @search.stub!(:get_facets).and_return(@date_facets)
    @search.send(:create_date_facets, @result_set)
    @search.timeline_anchor.should be_nil
  end
  
end

describe Search, ' when getting speaker facets' do

  def setup_search 
    @search = Search.new({:query => 'query'})
    @result_set = mock('result set')
    @search.stub!(:get_facets).and_return({'33' => 3, '22' => 4, '44' => 2})
  end
  
  before do
    @a_person = mock_model(Person, :name => "Aaa Aaa", :id => 33)
    @b_person = mock_model(Person, :name => "Bbb Bbb", :id => 22)
    @c_person = mock_model(Person,:name => "Ccc Ccc", :id => 44)
    Person.stub!(:find)
    Person.stub!(:find).and_return([@b_person, @a_person, @c_person])
    setup_search
  end

  it 'should return an empty list if there are no speaker facets in the result set' do 
    @search.stub!(:get_facets).and_return(nil)
    @search.send(:create_speaker_facets, @result_set).should == []
  end
  
  it 'should not return speakers whose count is 1' do
    @search.stub!(:get_facets).and_return({'33' => 3, '22' => 4, '44' => 1})
    @search.send(:create_speaker_facets, @result_set).include?([@c_person, 1]).should be_false
  end

  it 'should return the speaker name facets sorted by count if there are member name facets' do
    @search.send(:create_speaker_facets, @result_set).should == [[@b_person, 4], [@a_person, 3], [@c_person, 2]]
  end
    
  it 'should ask for people to populate the facets' do 
    Person.should_receive(:find).and_return([])
    @search.send(:create_speaker_facets, @result_set)
  end
  
end

describe Search, " when getting sitting type facets" do 

  before do 
    @result_set = mock('result set')
    @search = Search.new(:query => 'query')
  end
  
  it 'should return an empty list if there are no sitting type facets in the result set' do 
    @search.stub!(:get_facets).with(@result_set, "sitting_type_facet").and_return(nil)
    @search.send(:create_sitting_type_facets, @result_set).should == []
  end
  
  it 'should return a list of sitting types sorted alphabetically' do 
    sitting_type_facet = {"HouseCommonsSitting" => 3, "HouseLordsSitting" => 4}
    @search.stub!(:get_facets).with(@result_set, "sitting_type_facet").and_return(sitting_type_facet)
    expected = [["HouseLordsSitting", 4],["HouseCommonsSitting", 3]]
    @search.send(:create_sitting_type_facets, @result_set).should == expected
  end
  
end

describe Search, " when asked if it has a date filter" do 

  it 'should return true if the resolution and start date are set' do 
    search = Search.new(:query => 'query')
    search.stub!(:start_date).and_return(Date.new(2001, 2, 1))
    search.stub!(:resolution).and_return(:year)
    search.date_filter?.should be_true
  end
end

describe Search, " when asked if it has any facets" do 
  
  it 'should return true if there is more than one member facet to display' do 
    search = Search.new(:query => 'query')
    search.stub!(:sitting_type_facets).and_return([])
    search.stub!(:display_speaker_facets).and_return(["one", "two"])
    search.any_facets?.should be_true
    search.stub!(:display_speaker_facets).and_return(["one"])
    search.any_facets?.should be_false
  end
  
  it 'should return true if there is more than one sitting type facet to display' do 
    search = Search.new(:query => 'query', :display_speaker_facets => [])
    search.stub!(:display_speaker_facets).and_return([])
    search.stub!(:sitting_type_facets).and_return(["one", "two"])
    search.any_facets?.should be_true
    search.stub!(:sitting_type_facets).and_return(["one"])
    search.any_facets?.should be_false
  end 

end

describe Search, 'when asked for the indexes of a query when the page is 5 and the number per page is 10' do 
  
  before do 
    @search = Search.new(:query => 'test', :page => 5, :num_per_page => 10)
  end
  
  it 'should return an offset of 40' do 
    @search.offset.should == 40
  end
  
  it 'should return a first result of 41' do 
    @search.first_result.should == 41
  end
  
  it 'should return a last result of 50' do 
    @search.stub!(:results_size).and_return(55)
    @search.last_result.should == 50
  end
  
end