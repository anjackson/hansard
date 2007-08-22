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

describe Section, ".first_image_source" do
  
  it "should return the first image source " do
    section = Section.new(:start_image_src => "image2")
    section.first_image_source.should == "image2"
  end
  
  it "should return nil if the contribution has no image sources" do
    section = Section.new(:start_image_src => nil)
    section.first_image_source.should be_nil
  end
  
end
