require File.dirname(__FILE__) + '/../spec_helper'

def mock_oral_question_section_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:section).and_yield
  mock_builder.stub!(:title)
  mock_builder
end

describe OralQuestionSection, " in general" do

  before(:each) do
    @model = OralQuestionSection.new
    @mock_builder = mock_oral_question_section_builder
  end

  it_should_behave_like "an xml-generating model"

end

describe OralQuestionSection, ".to_xml" do

  before do
    @mock_builder = mock_oral_question_section_builder
    @section = OralQuestionSection.new
    @contribution_class = MemberContribution
  end

  it "should have a 'section' tag" do
    @section.to_xml.should have_tag("section")
  end

  it "should have one 'title' tag within the 'section' tag containing the question section title " do
    @section.title = "test title"
    @section.to_xml.should have_tag("section title", :text => "test title", :count => 1)
  end

  it_should_behave_like "a section to_xml method"
end

