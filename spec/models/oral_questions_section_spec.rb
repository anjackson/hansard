require File.dirname(__FILE__) + '/../spec_helper'


describe OralQuestionsSection, " in general" do
  
  before(:each) do
    @model = OralQuestionsSection.new
    @mock_builder = mock("xml builder")   
    @mock_builder.stub!(:title) 
  end
  
  it_should_behave_like "an xml-generating model"

end

describe OralQuestionsSection, ".to_xml" do
  
  before do
    @mock_builder = mock("xml builder")    
    @oral_questions_section = OralQuestionsSection.new
  end
  
  it "should call the to_xml method on each of it's questions, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    first_question = mock_model(OralQuestionSection)
    second_question = mock_model(OralQuestionSection)
    @oral_questions_section.questions << first_question
    @oral_questions_section.questions << second_question
    first_question.should_receive(:to_xml).with(:builder => @mock_builder)
    second_question.should_receive(:to_xml).with(:builder => @mock_builder)
    @oral_questions_section.to_xml
  end
  
end

