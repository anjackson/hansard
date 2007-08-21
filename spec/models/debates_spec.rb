require File.dirname(__FILE__) + '/../spec_helper'

def mock_debates_builder
  mock_builder = mock("xml builder")   
  mock_builder.stub!(:debates).and_yield
  mock_builder
end

describe Debates, " in general" do
  
  before(:each) do
    @model = Debates.new
    @mock_builder = mock_debates_builder 
  end
  
  it_should_behave_like "an xml-generating model"

end

describe Debates, ".to_xml" do
  
  before do
    @mock_builder = mock_debates_builder 
    @section = Debates.new
    @subsection_class = Section
    @contribution_class = Contribution
  end
  
  it "should not have a title tag" do
    @section.to_xml.should_not have_tag("title")
  end
  
  it "should have a 'debates' tag as it's outer element" do
    @section.to_xml.should match(/^<debates>.*?<\/debates>$/)
  end
  
  it_should_behave_like "a section to_xml method"

end

