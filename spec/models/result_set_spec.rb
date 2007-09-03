require File.dirname(__FILE__) + '/../spec_helper'

describe ResultSet, " when run against search_result_example.xml" do
  before do
    data = File.open("#{RAILS_ROOT}/spec/data/search_result_example.xml")
    @result_set = ResultSet.new(data)
    @first_result = @result_set.hits.first
    @last_result = @result_set.hits.last
  end
  
  it "should recognize that the first result is the first in the total result set" do
    @result_set.first.should == 1
  end
  
  it "should recognize that the last result is the tenth in the total result set" do
    @result_set.last.should == 10
  end
  
  it "should recognize that the total number of results is 141" do
    @result_set.total.should == 141
  end
  
  it "should parse out 10 hits" do
    @result_set.hits.size.should == 10
  end
  
  it "should parse the link to the first result correctly" do
    @first_result[:link].should == "http://rua.parliament.uk/members/individuals/591"
  end 
  
  it "should parse the title of the first result correctly" do
    @first_result[:title].should == "Calendar: Person: James Gordon <b>Brown</b>"
  end
  
  it "should parse the text of the first result correctly" do
    @first_result[:text][0..90].should == "<b>...</b> James Gordon <b>Brown</b>. Birthplace Scotland. Date of Birth: 20 February 1951."
  end
  
  it "should parse the link text of the first result correctly" do
    @first_result[:link_text].should == "http://rua.parliament.uk/members/individuals/591"
  end
end