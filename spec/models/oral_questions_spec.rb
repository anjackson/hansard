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
    @section = OralQuestions.new
    @subsection_class = OralQuestionsSection
  end
  
  it "should have one 'title' tag containing the title " do
     @section.title = "test title"
     @section.to_xml.should have_tag("title", :text => "test title", :count => 1)
   end
  
  it "should have an 'oralquestions' tag" do
    @section.to_xml.should have_tag("oralquestions", :count => 1)
  end
  
  it_should_behave_like "a section to_xml method"
  
end
