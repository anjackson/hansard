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
    @member_contribution = MemberContribution.new
    @member_contribution.member = "test member"
  end
    
   it "should return one 'p' tag with the id attribute set to the xml_id of the contribution" do
     @member_contribution.xml_id = "testid"
     @member_contribution.to_xml.should have_tag('p[id=testid]', :count => 1)
   end
   
   it "should return one 'p' tag with no content if the text of the oral question contribution is nil" do
     @member_contribution.text = nil
     @member_contribution.to_xml.should have_tag('p', :text => nil, :count => 1)
   end
   
   it "should return a 'p' tag containing one 'membercontribution' tag containing the text of the oral question contribution if it exists" do
     the_expected_text = "Some text I expected"
     @member_contribution.text = the_expected_text
     @member_contribution.to_xml.should have_tag('p membercontribution', :text => the_expected_text, :count => 1)
   end 
   
   it "should have a 'memberconstituency' tag inside the 'member' tag containing the constituency if the contribution has a constituency" do
     @member_contribution.member_constituency = "test constituency"
     @member_contribution.to_xml.should have_tag('member memberconstituency', :text => "test constituency", :count => 1)
   end
   
   it "should return a 'p' tag whose text starts with the oral question contribution number if the oral question contribution has one" do
     the_oral_question_no = "1."
     @member_contribution.oral_question_no = the_oral_question_no
     @member_contribution.to_xml.should have_tag('p', :text => /^#{the_oral_question_no}/, :count => 1)
   end
   
   it "should return a 'p' tag containing one member tag (and no text) if the oral question contribution has no oral question number" do
     @member_contribution.oral_question_no = nil
     @member_contribution.to_xml.should have_tag('p', :text => nil, :count => 1)
     @member_contribution.to_xml.should have_tag('p member', :count => 1)
   end
   
   it "should return one 'member' tag containing the member attribute of the oral question contribution" do
     @member_contribution.member = "John Q. Member"
     @member_contribution.to_xml.should have_tag('member', :text => "John Q. Member", :count => 1) 
   end  
   
   it "should contain one 'membercontribution' tag containing the oral question contribution text" do
     @member_contribution.text = "Is this a question?"
     @member_contribution.to_xml.should have_tag("membercontribution", "Is this a question?")
   end
   
end

