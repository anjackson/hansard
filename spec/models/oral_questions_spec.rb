require File.dirname(__FILE__) + '/../spec_helper'

def mock_oral_questions_builder
  mock_builder = mock("xml builder") 
  mock_builder.stub!(:title)  
  mock_builder.stub!(:oralquestions).and_yield
  mock_builder
end

describe OralQuestions, " in general" do
  
  before(:each) do
    @model = OralQuestions.new
    @mock_builder = mock_oral_questions_builder
  end
    
  it_should_behave_like "an xml-generating model"

end

describe OralQuestions, ".to_xml" do
  
  before do
    @mock_builder = mock_oral_questions_builder
    @oral_questions = OralQuestions.new
  end
  
  it "should have an 'oralquestions' tag" do
    @oral_questions.to_xml.should have_tag("oralquestions", :count => 1)
  end
  
  it "should have one 'title' tag containing the title " do
    @oral_questions.title = "test title"
    @oral_questions.to_xml.should have_tag("title", :text => "test title", :count => 1)
  end
  
  it "should call the to_xml method on each of it's contributions, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    first_contribution = mock_model(Contribution)
    second_contribution = mock_model(Contribution)
    @oral_questions.contributions << first_contribution
    @oral_questions.contributions << second_contribution
    first_contribution.should_receive(:to_xml).with(:builder => @mock_builder)
    second_contribution.should_receive(:to_xml).with(:builder => @mock_builder)
    @oral_questions.to_xml
  end
   
  it "should call the to_xml method on each of it's sections, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    first_oral_questions = mock_model(OralQuestionsSection)
    second_oral_questions = mock_model(OralQuestionsSection)
    @oral_questions.sections << first_oral_questions
    @oral_questions.sections << second_oral_questions
    first_oral_questions.should_receive(:to_xml).with(:builder => @mock_builder)
    second_oral_questions.should_receive(:to_xml).with(:builder => @mock_builder)
    @oral_questions.to_xml
  end
  
end
