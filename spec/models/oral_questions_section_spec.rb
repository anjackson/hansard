require File.dirname(__FILE__) + '/../spec_helper'

def mock_oral_questions_section_builder 
  mock_builder = mock("xml builder")   
  mock_builder.stub!(:title)
  mock_builder.stub!(:section).and_yield
  mock_builder
end

describe OralQuestionsSection, " in general" do
  
  before(:each) do
    @model = OralQuestionsSection.new
    @mock_builder = mock_oral_questions_section_builder
  end
  
  it_should_behave_like "an xml-generating model"

end

describe OralQuestionsSection, ".to_xml" do
  
  before do
    @mock_builder = mock_oral_questions_section_builder
    @oral_questions_section = OralQuestionsSection.new
  end
  
  it "should have a 'section' tag " do
    @oral_questions_section.to_xml.should have_tag("section", :count => 1)
  end
  
  it "should have one 'title' tag containing the title " do
    @oral_questions_section.title = "test title"
    @oral_questions_section.to_xml.should have_tag("title", :text => "test title", :count => 1)
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

