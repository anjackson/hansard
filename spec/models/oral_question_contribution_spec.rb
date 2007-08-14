require File.dirname(__FILE__) + '/../spec_helper'

describe OralQuestionContribution, " in general" do
  
  before(:each) do
    @oral_question_contribution = OralQuestionContribution.new
  end
  
  it "should respond to activerecord_xml" do
    @oral_question_contribution.respond_to?("to_activerecord_xml").should be_true
  end
  
  it "should respond to xml" do
    @oral_question_contribution.respond_to?("to_xml").should be_true
  end
  
  it "should have different methods to_xml and activerecord_to_xml" do
    @oral_question_contribution.to_xml.should_not eql(@oral_question_contribution.to_activerecord_xml)
  end
  
end

describe OralQuestionContribution, ".to_xml" do
  
  before do
    @mock_builder = mock("xml builder")    
    @oral_question_contribution = OralQuestionContribution.new
    @mock_builder.stub!(:p)
  end
  
  it "should produce some output" do
    @oral_question_contribution.to_xml.should_not be_nil
  end
  
  it "should create an xml builder if it is not passed one in the options hash" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    @oral_question_contribution.to_xml
  end
  
   it "should not create an xml builder if one is passed to it in the :builder param of the options hash" do
     Builder::XmlMarkup.should_not_receive(:new)
     @oral_question_contribution.to_xml(:builder => @mock_builder)
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
   
   it "should return a 'p' tag containing a member"
    
end

