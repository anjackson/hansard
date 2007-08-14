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
   
   it "should return a 'p' tag with the id attribute set to the xml_id of the contribution" do
     @oral_question_contribution.xml_id = "testid"
     print @oral_question_contribution.to_xml
     @oral_question_contribution.to_xml.should have_tag('p[id=testid]')
   end
  
end

