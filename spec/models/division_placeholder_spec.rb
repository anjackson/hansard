require File.dirname(__FILE__) + '/../spec_helper'

def mock_divisions_placeholder_builder
  mock_builder = mock("xml builder") 
  mock_builder
end

describe DivisionPlaceholder, ".to_xml" do
  
  before do
    @division_placeholder = DivisionPlaceholder.new
  end
  
  it "should ask it's division for xml" do
    @division = Division.new
    @division_placeholder.division = @division
    @division.should_receive(:to_xml)
    @division_placeholder.to_xml
  end
  
end
