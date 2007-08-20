require File.dirname(__FILE__) + '/../spec_helper'


describe OralQuestionContribution, " in general" do
  
  before(:each) do
    @model = OralQuestionContribution.new
    @mock_builder = mock("xml builder")    
    @mock_builder.stub!(:p)
  end
  
  it_should_behave_like "an xml-generating model"
  
end

describe OralQuestionContribution, ".to_xml" do
  
  before do
    @oral_question_contribution = OralQuestionContribution.new
  end
    
   it "should return one 'p' tag with the id attribute set to the xml_id of the contribution" do
     @oral_question_contribution.xml_id = "testid"
     @oral_question_contribution.to_xml.should have_tag('p[id=testid]', :count => 1)
   end
   
   it "should return one 'p' tag with no content if the text of the oral question contribution is nil" do
     @oral_question_contribution.text = nil
     @oral_question_contribution.to_xml.should have_tag('p', :text => nil, :count => 1)
   end
   
   it "should return a 'p' tag containing one 'membercontribution' tag containing the text of the oral question contribution if it exists" do
     the_expected_text = "Some text I expected"
     @oral_question_contribution.text = the_expected_text
     @oral_question_contribution.to_xml.should have_tag('p membercontribution', :text => the_expected_text, :count => 1)
   end 
   
   it "should return a 'p' tag whose text starts with the oral question contribution number if the oral question contribution has one" do
     the_oral_question_no = "1."
     @oral_question_contribution.oral_question_no = the_oral_question_no
     @oral_question_contribution.to_xml.should have_tag('p', :text => /^#{the_oral_question_no}/, :count => 1)
   end
   
   it "should return a 'p' tag containing one member tag (and no text) if the oral question contribution has no oral question number" do
     @oral_question_contribution.oral_question_no = nil
     @oral_question_contribution.to_xml.should have_tag('p', :text => nil, :count => 1)
     @oral_question_contribution.to_xml.should have_tag('p member', :count => 1)
   end
   
   it "should return one 'member' tag containing the member attribute of the oral question contribution" do
     @oral_question_contribution.member = "John Q. Member"
     @oral_question_contribution.to_xml.should have_tag('member', :text => "John Q. Member", :count => 1) 
   end  
   
   it "should contain one 'membercontribution' tag containing the oral question contribution text" do
     @oral_question_contribution.text = "Is this a question?"
     @oral_question_contribution.to_xml.should have_tag("membercontribution", "Is this a question?")
   end
   
   
end

