require File.dirname(__FILE__) + '/../spec_helper'

describe SearchHelper, " when formatting search result text fragments" do

  it "should replace leading punctuation" do
    format_result_fragment(':this starts with a colon').should == 'this starts with a colon'  
  end
  
  it "should unescape entities" do
    format_result_fragment('&#34;entity').should == '"entity'
  end
  
end

describe SearchHelper, " when formatting member names" do
 
  it "should unescape entities" do
    format_member_name('&#34;entity').should == '"entity'
  end

end

describe SearchHelper, " when creating a search result title" do
 
  it "should return 'Search: <code>mice</code>' for a query of 'mice' and no member" do
    search_results_title(nil, nil, 'mice').should == 'Search: \'mice\''
  end

  it "should return 'Search: \'mice\' spoken by Mickey Mouse' for a query of 'mice' and member 'Mickey Mouse' " do
    stub!(:link_to_member).and_return('<a href="">Mickey Mouse</a>')
    search_results_title('Mickey Mouse', nil, 'mice').should == 'Search: \'mice\' spoken by <a href="">Mickey Mouse</a>'
  end
  
  it "should return 'Search: \'mice\' spoken in the 1920s' for a query of 'mice' and decade '1920s'" do
    search_results_title(nil, '1920s', 'mice').should == 'Search: \'mice\' in the 1920s'
  end

end

describe SearchHelper, " when creating member facet links" do
  
  it 'should return "<a href=\"/search?member=Mickey+Mouse&amp;query=mice\"><strong>4</strong> Mickey Mouse</a>" for member Mickey Mouse with 4 hits' do
    member_facet_link("Mickey Mouse", 4, "mice").should == "<a href=\"/search?member=Mickey+Mouse&amp;query=mice\"><strong>4</strong> Mickey Mouse</a>"
  end 

end

describe SearchHelper, ".link_for" do

  it 'should return the text "1950s" when passed the interval "1950s", century resolution and a list of zero counts' do
    link_for('1950s', :century, [0,0,0,0,0], {}).should == '1950s'
  end
  
  it 'should return a link to the search url with query and decade params set when passed the interval "1950s", century resolution and some non-zero counts' do
    @query = "test"
    link_for('1950s', :century, [0,1,0,0,1], {}).should == '<a href="/search?decade=1950s&amp;query=test">1950s</a>'
  end
  
end

describe SearchHelper, " when creating a date timeline for a result set" do
  
  before do 
    @result_set = mock("result set")
  end

  it 'should not return anything if the result set has no facets' do
    @result_set.stub!(:facets).and_return(nil)
    date_timeline(@result_set).should be_nil
  end
  
  it 'should not return anything if the results set has no facet fields' do
    @result_set.stub!(:facets).and_return({})
    date_timeline(@result_set).should be_nil
  end
 
  it 'should not return anything if the results set facet fields do not include a date facet'  do
    @result_set.stub!(:facets).and_return({:facet_fields => {}})
    date_timeline(@result_set).should be_nil
  end
  
end


