require File.dirname(__FILE__) + '/../spec_helper'

def mock_section_builder
  mock_builder = mock("xml builder") 
  mock_builder.stub!(:title)  
  mock_builder.stub!(:section).and_yield
  mock_builder
end

describe Section, " in general" do
  
  before(:each) do
    @model = Section.new
    @mock_builder = mock_section_builder
  end
  
  it_should_behave_like "an xml-generating model"

end

describe Section, ".to_xml" do
  
  before do
    @mock_builder = mock_section_builder
    @section = Section.new
    @subsection_class = Section
    @contribution_class = Contribution
  end
  
  it "should have a 'section' tag as it's outer element" do
    @section.to_xml.should have_tag("section", :count => 1)
  end
  
  it "should have one 'title' tag containing the title " do
    @section.title = "test title"
    @section.to_xml.should have_tag("title", :text => "test title", :count => 1)
  end
  
  it_should_behave_like "a section to_xml method"
  
end
