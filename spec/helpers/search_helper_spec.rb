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
    search_results_title(nil, 'mice').should == 'Search: \'mice\''
  end
  
end

describe SearchHelper, " when creating member facet links" do
  
  it 'should return "<a href=\"/search?member=Mickey+Mouse&amp;query=mice\"><strong>4</strong> Mickey Mouse</a>" for member Mickey Mouse with 4 hits' do
    member_facet_link("Mickey Mouse", 4, "mice").should == "<a href=\"/search?member=Mickey+Mouse&amp;query=mice\"><strong>4</strong> Mickey Mouse</a>"
  end 

end
