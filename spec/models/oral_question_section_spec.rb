require File.dirname(__FILE__) + '/../spec_helper'


describe OralQuestionSection, " in general" do
  
  before(:each) do
    @model = OralQuestionSection.new
    @mock_builder = mock("xml builder") 
    @mock_builder.stub!(:section) 
    @mock_builder.stub!(:title)  
  end
    
  it_should_behave_like "an xml-generating model"

end

describe OralQuestionSection, ".to_xml" do
  
  before do
    @mock_builder = mock("xml builder")    
    @mock_builder.stub!(:section).and_yield
    @mock_builder.stub!(:title)
    @oral_question_section = OralQuestionSection.new
  end
 
  it "should have a 'section' tag" do
    @oral_question_section.to_xml.should have_tag("section")
  end
  
  it "should have one 'title' tag within the 'section' tag containing the question section title " do
    @oral_question_section.title = "test title"
    @oral_question_section.to_xml.should have_tag("section title", :text => "test title", :count => 1)
  end
  
  it "should call the to_xml method on each of it's contributions, passing it's xml builder" do
    Builder::XmlMarkup.should_receive(:new).and_return(@mock_builder)
    first_contribution = mock_model(OralQuestionContribution)
    second_contribution = mock_model(OralQuestionContribution)
    @oral_question_section.contributions << first_contribution
    @oral_question_section.contributions << second_contribution
    first_contribution.should_receive(:to_xml).with(:builder => @mock_builder)
    second_contribution.should_receive(:to_xml).with(:builder => @mock_builder)
    @oral_question_section.to_xml
  end
  
end

