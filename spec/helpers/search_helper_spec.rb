require File.dirname(__FILE__) + '/../spec_helper'

describe SearchHelper do 
  
  before do 
    self.class.send(:include, ApplicationHelper)
    self.class.send(:include, SearchHelper)
  end
  
  describe " when getting hit text fragments" do

    before do
      highlights = {1 => ["fragment one", "fragment two"]}
      @contribution = mock_model(Contribution, :id => 1)
      @expected_fragment = 'fragment one &hellip; fragment two'
      @search = mock_model(Search, :query => 'test', 
                                   :highlight_prefix => nil, 
                                   :highlight_suffix => nil, 
                                   :highlights => highlights)
    end

    it "should make a fragment from the contribution text fragments in the result set joined by ellipses" do
      hit_fragment(@contribution, @search).should == @expected_fragment
    end

    it "should format the fragment" do
      should_receive(:format_result_fragment).and_return(@expected_fragment)
      hit_fragment(@contribution, @search)
    end

    it 'should assign an empty string to the fragment if there are no contribution text fragments in the result set' do
      @search.stub!(:highlights).and_return(1 => nil)
      hit_fragment(@contribution, @search).should == ''
    end

  end

  describe " when formatting search result text fragments" do

    before do 
      @search = mock_model(Search, :query => 'test', :highlight_prefix => '<em>', :highlight_suffix => '</em>')  
    end
  
    it "should replace leading punctuation" do
      format_result_fragment(':this starts with a colon', @search).should == 'this starts with a colon'
    end

    it "should replace '&amp;' with '&' " do
      format_result_fragment('&amp;#34;entity', @search).should == '&#34;entity'
    end

    it 'should strip a broken entity from the beginning of the string' do 
      format_result_fragment('#x2013;2000 onwards.', @search).should == '2000 onwards.'
    end
  
    it 'should remove highlighting of the stemmed word "contribution" if the query does not contain the word' do 
      format_result_fragment('he made a big <em>contribution</em> to stuff', @search).should == 'he made a big contribution to stuff'
    end
  
    it 'should not remove highlighting of the stemmed word "contribution" if the query contains the word' do
      @search.stub!(:query).and_return('contributed') 
      format_result_fragment('he made a big <em>contribution</em> to stuff', @search).should == 'he made a big <em>contribution</em> to stuff'
    end
  end

  describe " when displaying search filters" do 
  
    before do
      stub!(:params).and_return({:controller => 'search', :action => 'show'})
    end
  
    def expect_filter(filter, text, search)
      show_filter(filter, search).should match(/#{text}/)
    end
  
    it 'should include a link with the times symbol to the search without the filter and without any page param' do 
      stub!(:params).and_return({:controller => 'search', 'decade' => '2000s', :action => 'show', 'page' => '2'})
      show_filter(Date.new(2006, 1, 1),  mock_model(Search, :resolution => :decade)).should have_tag('a[href=/search]')
    end
  
    it 'should return text "2000s" for filter date 2006-01-01 at a decade resolution' do 
      expect_filter(Date.new(2006, 1, 1), "2000s", mock_model(Search, :resolution => :decade))
    end
  
    it 'should return text "2006" for filter date 2006-01-01 at a year resolution' do 
      expect_filter(Date.new(2006, 1, 1), "2006", mock_model(Search, :resolution => :year))    
    end
  
    it 'should return text "Jan 2006" for filter date 2006-01-01 at a month resolution' do 
      expect_filter(Date.new(2006, 1, 1), "January 2006", mock_model(Search, :resolution => :month))
    end
  
    it 'should return text "1 Jan 2006" for filter date 2006-01-01 at a day resolution' do 
      expect_filter(Date.new(2006, 1, 1), "1 January 2006", mock_model(Search, :resolution => :day))
    end
    
    it 'should return text "Bob Person" for filter with person whose name is "Bob Person"' do 
      expect_filter(mock_model(Person, :name => "Bob Person"), "Bob Person", mock_model(Search))
    end
  
    it 'should return text "Written Answers" for filter "Written Answers"' do 
      expect_filter("Written Answers", "Written Answers", mock_model(Search))
    end
  
  end

  describe " when creating speaker facet links" do

    before(:each) do
      @person = Person.new(:firstname => "Mickey", :lastname => "Mouse", :slug => 'mickey-mouse')
      stub!(:params).and_return(:controller => 'search', :action => 'show')
    end
  
    it 'should remove any page param from the link' do 
      stub!(:params).and_return(:controller => 'search', :action => 'show', :page => '2')
      speaker_facet_link(@person, nil, "mice", {:times => 4}).should == "<a href=\"/search/mice?speaker=mickey-mouse\" title=\"Show only results from Mickey Mouse\">Mickey Mouse <span class='facet_times'>(4)</span></a>"
    end

    it 'should return "<a href=\"/search?speaker=mickey-mouse&amp;query=mice\">Mickey Mouse (4)</a>" for person Mickey Mouse with 4 hits' do
      speaker_facet_link(@person, nil, "mice", {:times => 4}).should == "<a href=\"/search/mice?speaker=mickey-mouse\" title=\"Show only results from Mickey Mouse\">Mickey Mouse <span class='facet_times'>(4)</span></a>"
    end
    
    it 'should return "<a href=\"/search?speaker=mickey-mouse&amp;query=mice\">Mickey Mouse</a>" for person Mickey Mouse with only one hit' do
      speaker_facet_link(@person, nil,  "mice", {:times => 1}).should == "<a href=\"/search/mice?speaker=mickey-mouse\" title=\"Show only results from Mickey Mouse\">Mickey Mouse</a>"
    end

    it 'should return "<a href=\"/search?speaker=mickey-mouse&amp;query=mice\">M Mouse</a>" for person Mickey Mouse, with name "M Mouse" with only one hit' do
      speaker_facet_link(@person, "M Mouse",  "mice", {:times => 1}).should == "<a href=\"/search/mice?speaker=mickey-mouse\" title=\"Show only results from M Mouse\">M Mouse</a>"
    end
    
  end

  describe " when creating sitting type facet links" do

    before(:each) do
      stub!(:params).and_return(:controller => 'search', :action => 'show')
    end
  
    it 'should remove any page param from the link' do 
      stub!(:params).and_return(:controller => 'search', :action => 'show', :page => '2')
      sitting_type_facet_link("Written Answers", "mice").should == "<a href=\"/search/mice?type=Written+Answers\" title=\"Show only results from Written Answers\">Written Answers</a>"
    end
  
    it 'should return "<a href=\"/search/mice?type=Written+Answers\" title=\"Show only results from Written Answersy\">Written Answers</a>" for sitting type "Written Answers"' do
      sitting_type_facet_link("Written Answers", "mice").should == "<a href=\"/search/mice?type=Written+Answers\" title=\"Show only results from Written Answers\">Written Answers</a>"
    end
  
    it 'should return "<a href=\"/search/mice?type=Written+Answers\" title=\"Show only results from Written Answers\">WA (5)</a>" for sitting type "Written Answers" and text "WA (5)"' do
      sitting_type_facet_link("Written Answers", "mice", "WA (5)").should == "<a href=\"/search/mice?type=Written+Answers\" title=\"Show only results from Written Answers\">WA (5)</a>"
    end

  end

  describe " when creating the search results sort link" do

    describe "if the current sort is not set" do 
    
      before do 
        stub!(:params).and_return({:controller => "search", :action => "show"})
        @links = sort_links(nil, params)
      end
    
      it 'should return a link to the search url with sort=date with the text "Sort by EARLIEST"' do
        @links.should have_tag('a[href=/search?sort=date]', :text => 'Sort by EARLIEST')
      end
  
      it 'should return a link to the seach url with sort=reverse_date with the text "Sort by MOST RECENT"' do
        @links.should have_tag('a[href=/search?sort=reverse_date]', :text => 'Sort by MOST RECENT')
      end
  
      it 'should not return a link to the search url without a sort specified with the text "Sort by MOST RELEVANT"' do 
        @links.should_not have_tag('a[href=/search]', :text => 'Sort by MOST RELEVANT')
      end
    
      it 'should remove the "page" parameter from the url' do 
        links = sort_links(nil, {:controller => 'search', :action => 'show', :page => '5'})
        links.should have_tag('a[href=/search?sort=date]')
      end
  
    end
  
    describe "if the current sort is 'date' " do 
   
      before do
        stub!(:params).and_return({:controller => "search", :action => "show"})
        @links = sort_links("date", params) 
      end
    
      it 'should return a link to the search url without sort param with the text "Sort by MOST RELEVANT"' do
        @links.should have_tag('a[href=/search]', :text => 'Sort by MOST RELEVANT')
      end
    
      it 'should return a link to the search url url with sort=reverse_date with the text "Sort by MOST RECENT"' do
        @links.should have_tag('a[href=/search?sort=reverse_date]', :text => 'Sort by MOST RECENT')
      end
    
      it 'should return the text "Sort by EARLIEST" within a link to the search url with sort=date' do 
        @links.should_not have_tag('a[href=/search?sort=date]', :text => 'Sort by EARLIEST')
      end 
    
    end

    describe "if the current sort is 'reverse_date' " do 
   
      before do
        stub!(:params).and_return({:controller => "search", :action => "show"})
        @links = sort_links("reverse_date", params) 
      end
    
      it 'should return a link to a url without sort param containing a button with the text "Sort by MOST RELEVANT"' do
        @links.should have_tag('a[href=/search]', :text => 'Sort by MOST RELEVANT')
      end
    
      it 'should return a link to a url with sort=date containing a button with the text "Sort by EARLIEST"' do
        @links.should have_tag('a[href=/search?sort=date]', :text => 'Sort by EARLIEST')
      end

      it 'should not return a link to the search url with sort=reverse_date containing a button with the text "Sort by MOST RECENT"' do 
        @links.should_not have_tag('a[href=/search?sort=reverse_date]', :text => 'Sort by MOST RECENT')
      end 
    
    end
  
  end

  describe " when creating a date timeline for a result set" do
  
    before do 
      @date = mock("date")
      stub!(:timeline_options).and_return({})
      @timeline_anchor = Date.new(2005,12,11) 
    end
  
    it 'should return a timeline if the result set has no date facets but does have a date filter' do
      should_receive(:timeline)
      search = mock_model(Search, :date_facets => {}, 
                                  :start_date => @date,
                                  :timeline_anchor => nil,
                                  :date_filter? => true, 
                                  :resolution => nil)
      search_timeline(search)
    end
  
    it 'should not return a timeline if the result set has no date facets or date filter' do
      should_not_receive(:timeline)
      search = mock_model(Search, :date_facets => {}, 
                                  :date_filter? => false, 
                                  :timeline_anchor => nil,
                                  :resolution => nil)
      search_timeline(search)
    end

    it 'should not return a timeline if the search is at the day resolution' do
      should_not_receive(:timeline)
      search = mock_model(Search, :date_facets => {}, 
                                  :date_filter? => false, 
                                  :timeline_anchor => nil,
                                  :resolution => :day)
      search_timeline(search)
    end
  
    it 'should get a timeline for a decade resolution back from the start date defined in the search with top label "Results by decade"' do
      should_receive(:timeline).with(@date, :decade, {:top_label => "Results by decade"})
      search = mock_model(Search, :date_facets => { Date.new(2005,11,11) => 1 }, 
                                  :start_date => @date,
                                  :timeline_anchor => nil,
                                  :resolution => nil)    
      search_timeline(search)
    end
  
    it 'should pass the timeline the timeline anchor date if there is one' do 
      should_receive(:timeline).with(@timeline_anchor, :decade, {:top_label => "Results by decade"})
      search = mock_model(Search, :date_facets => { Date.new(2005,11,11) => 1 }, 
                                  :start_date => @date,
                                  :timeline_anchor => @timeline_anchor, 
                                  :resolution => nil)
      search_timeline(search)
    end
  
    it 'should pass the timeline the start date of the search if there is not a timeline anchor date' do 
      should_receive(:timeline).with(@date, :decade, {:top_label => "Results by decade"})
      search = mock_model(Search, :date_facets => { Date.new(2005,11,11) => 1 }, 
                                  :start_date => @date,
                                  :timeline_anchor => nil, 
                                  :resolution => nil)
      search_timeline(search)
    end

  end

  describe " when creating timeline urls" do 
  
    before do 
      stub!(:params).and_return(:action => 'show', :controller => 'search')
    end
  
    it 'should strip a page param from the params' do 
      stub!(:params).and_return(:action => 'show', :controller => 'search', 'page' => '3')
      timeline_url("C20", {}, nil).should == "/search?century=C20"
    end
  
    it 'should strip a century param from the params' do 
      stub!(:params).and_return(:action => 'show', :controller => 'search', 'century' => 'C20')
      timeline_url("2000s", {}, :decade).should == "/search?decade=2000s"
    end
  
    it 'should strip a decade param from the params if the resolution is year' do 
      stub!(:params).and_return(:action => 'show', :controller => 'search', 'decade' => '2000s')
      timeline_url("2001", {}, :year).should == "/search?year=2001"
    end
  
    it 'should strip a month param from the params if the resolution is year' do 
      stub!(:params).and_return(:action => 'show', :controller => 'search', 'month' => '2001-6')
      timeline_url("2001", {}, :year).should == "/search?year=2001"
    end
  
    it 'should return a URL with century set to "C20" for interval "C20" and resolution nil' do 
      timeline_url("C20", {}, nil).should == "/search?century=C20"
    end
  
    it 'should return a URL with decade set to "2000s" for interval "2000s" and resolution :decade' do 
      timeline_url("2000s", {}, :decade).should == "/search?decade=2000s"
    end
  
    it 'should return a URL with year set to "2010" for interval "2010" and resolution :year' do 
      timeline_url("2010", {}, :year).should == "/search?year=2010"
    end
  
    it 'should return a URL with month set to "1807-12" for interval "1807_12" and resolution :month' do 
      timeline_url("1807_12", {}, :month).should == "/search?month=1807-12"
    end
  
    it 'should return a URL with month set to "1807-12-1" for interval "1807-12-01" and resolution :day' do 
      timeline_url("1807-12-01", {}, :day).should == "/search?day=1807-12-01"
    end
  
  end

  describe " when creating a search results summary" do

    before do
      @search = mock_model(Search, :query => 'test',
                                   :num_per_page => 20, 
                                   :first_result => 1,
                                   :last_result => 20,
                                   :get_results => [],
                                   :results_size => 0)
    end

    it 'should include an "h3" tag showing the number of results if the number is less than is being shown per page' do
      @search.stub!(:results_size).and_return(17)
      @search.stub!(:get_results).and_return(["a result"])
      search_results_summary(@search).should have_tag('h3', :text => "17 results")
    end

    it 'should include an "h3" tag with the text "1 result" if there is only one result' do 
      @search.stub!(:results_size).and_return(1)
      @search.stub!(:get_results).and_return(["a result"])
      search_results_summary(@search).should have_tag('h3', :text => "1 result")
    end

    it 'should include an "h3" tag showing the number of hits shown and the total number of results otherwise' do
      @search.stub!(:results_size).and_return(23)
      @search.stub!(:get_results).and_return(["a result"])
      search_results_summary(@search).should have_tag('h3', :text => "Results 1 to 20 of 23")
    end
  
    it 'should include commas in numbers over a thousand' do 
      @search.stub!(:results_size).and_return(2300)
      @search.stub!(:first_result).and_return(1981)
      @search.stub!(:last_result).and_return(2000)    
      @search.stub!(:get_results).and_return(["a result"])
      search_results_summary(@search).should have_tag('h3', :text => "Results 1,981 to 2,000 of 2,300")
    end

  end

  describe " when creating timeline links" do 

    before do 
      @query = 'test'
      @test_params = {:controller => 'search', :action => 'show', :query => @query}
      stub!(:params).and_return(@test_params)
    end
  
    it 'should remove any page param from the link' do 
      stub!(:params).and_return(:controller => 'search', :action => 'show', 'page' => '2', :query => @query)
      timeline_link("label", nil, {}, nil).should have_tag("a[href=/search/test]", :text => "label")
    end

    it 'should create a link to "/search/test" for a query of test with no resolution specified' do 
      timeline_link("label", nil, {}, nil).should have_tag("a[href=/search/test]", :text => "label")
    end
  
    it 'should create a link with title "Results for \'test\' : Sittings by decade" for a query of test with no resolution specified and label "Sittings by decade"' do 
      timeline_link('Sittings by decade', nil, {}, nil).should have_tag("a[title=Results for 'test' : Sittings by decade]")
    end
  
    it 'should create a link to "/search/test/" for a query of test with decade resolution and interval "1950s"' do 
      timeline_link("label", "1950s", {}, :decade).should have_tag("a[href=/search/test?decade=1950s]", :text => "label")
    end
  
    it 'should create a link with title "Results for \'test\' in the 1950s" for a query of test with decade resolution and label "1950s"' do 
      timeline_link("1950s", "1950s", {}, :decade).should have_tag("a[title=Results for 'test' in the 1950s]")
    end
  
    it 'should create a link to "/search/test?year=1953" for a query of test with year resolution and interval "1953"' do 
      timeline_link("label", "1953", {}, :year).should have_tag("a[href=/search/test?year=1953]", :text => "label")
    end
  
    it 'should create a link with title "Results for \'test\' in 1953" for a query of test with year resolution and label "1953"' do 
      timeline_link("1953", "1953", {}, :year).should have_tag("a[title=Results for 'test' in 1953]")
    end
  
    it 'should create a link to "/search/test?month=2007-5" for a query of test with month resolution and interval "2007_5"' do 
      timeline_link("label", "2007_5", {}, :month).should have_tag("a[href=/search/test?month=2007-5]", :text => "label")
    end
  
    it 'should create a link with title "Results for \'test\' in May" for a query of test with month resolution and label "May"' do 
      timeline_link("May", "May", {}, :month).should have_tag("a[title=Results for 'test' in May]")
    end
  
    it 'should create a link to "/search/test?day=2007-5-12" for a query of test with decade resolution and interval "2007-5-12"' do 
      timeline_link("label", Date.new(2007, 5, 12), {}, :day).should have_tag("a[href=/search/test?day=2007-05-12]", :text => "label")
    end
  
    it 'should create a link with title "Results for \'test\' on May 12, 2007" for a query of test with day resolution and interval of a date in May' do 
      timeline_link("May", Date.new(2007, 5, 12), {}, :day).should have_tag("a[title=Results for 'test' on May 12, 2007]")
    end
  
    it 'should create a link to "/search/test?year=1953" for a query of test with year resolution and interval "1953" when the current page params include "decade=1950s"' do 
      stub!(:params).and_return(@test_params.merge('decade' => '1950s'))
      timeline_link("label", "1953", {}, :year).should have_tag("a[href=/search/test?year=1953]", :text => "label")
    end
 
    it 'should create a link to "/search/test?year=1953" for a query of test with year resolution and interval "1953" when the current page params include "month=1953-5"' do 
      stub!(:params).and_return(@test_params.merge('month' => '1953-5'))
      timeline_link("label", "1953", {}, :year).should have_tag("a[href=/search/test?year=1953]", :text => "label")
    end
  
  end

  describe " when asked for a speaker link" do 
    
    it 'should return a link to the person page for the speaker if the speaker is a person' do 
      speaker = mock_model(Person, :name => 'test name')
      stub!(:person_url).with(speaker).and_return("http://www.example.com")
      speaker_link(speaker).should have_tag('a[href=http://www.example.com]')
    end

  end

  describe " when asked for an interval suffix" do 
  
    it 'should return "" when passed an invalid resolution' do 
      interval_suffix(:not_a_resolution, "my-label", "my-interval").should == ""
    end

  end

  describe 'when creating search urls' do 
  
    before do 
      @paginator = mock('paginator')
    end
  
    it 'should pass params {:only_path => false, :page => 1} to url for when asked for the first results url' do
      should_receive(:url_for).with({'only_path' => false, 'page' => 1})
      first_results_url
    end
  
    it 'should pass params {:only_path => false, :page => 3} to url for when asked for the next results url for a paginator whose next page is 3' do
      @paginator.stub!(:next_page).and_return(3)
      should_receive(:url_for).with({'only_path' => false, 'page' => 3})
      next_results_url(@paginator)
    end
  
    it 'should pass params {:only_path => false, :page => 3} to url for when asked for the previous results url for a paginator whose previous page is 3' do
      @paginator.stub!(:previous_page).and_return(3)
      should_receive(:url_for).with({'only_path' => false, 'page' => 3})
      previous_results_url(@paginator)
    end
  
    it 'should pass params {:only_path => false, :page => 3} to url for when asked for the last results url for a paginator whose page count is 3' do
      @paginator.stub!(:total_pages).and_return(3)
      should_receive(:url_for).with({'only_path' => false, 'page' => 3})
      last_results_url(@paginator)
    end
  
  end

  describe "when asked for an atom url" do 
  
    before do
      stub!(:params).and_return({:controller => 'search', :action => 'show', :query => 'test', :page => '1'})
    end
  
    it 'should return a url in the form "search/test.atom?page=1"' do 
      atom_url.should == '/search/test.atom?page=1'
    end
  
  end

end
