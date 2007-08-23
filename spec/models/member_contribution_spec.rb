require File.dirname(__FILE__) + '/../spec_helper'


describe MemberContribution, " in general" do
  
  before(:each) do
    @model = MemberContribution.new
    @model.stub!(:member).and_return("test member")
    @mock_builder = mock("xml builder")  
    @mock_builder.stub!(:p)
  end
  
  it_should_behave_like "an xml-generating model"
  
end

describe MemberContribution, ".to_xml" do
  
  before do
    @contribution = MemberContribution.new
    @contribution.member = "test member"
  end
    
   it "should return one 'p' tag with no content if the text of the member contribution is nil" do
     @contribution.text = nil
     @contribution.to_xml.should have_tag('p', :text => nil, :count => 1)
   end
   
   it "should return a 'p' tag containing one 'membercontribution' tag containing the text of the oral question contribution if it exists" do
     the_expected_text = "Some text I expected"
     @contribution.text = the_expected_text
     @contribution.to_xml.should have_tag('p membercontribution', :text => the_expected_text, :count => 1)
   end 
   
   it "should have a 'memberconstituency' tag inside the 'member' tag containing the constituency if the contribution has a constituency" do
     @contribution.member_constituency = "test constituency"
     @contribution.to_xml.should have_tag('member memberconstituency', :text => "test constituency", :count => 1)
   end
   
   it "should return one 'member' tag containing the member attribute of member contribution" do
     @contribution.member = "John Q. Member"
     @contribution.to_xml.should have_tag('member', :text => "John Q. Member", :count => 1) 
   end  
   
   it "should contain one 'membercontribution' tag containing the member contribution text" do
     @contribution.text = "Is this a question?"
     @contribution.to_xml.should have_tag("membercontribution", "Is this a question?")
   end
   
   it_should_behave_like "a contribution"
   
end

