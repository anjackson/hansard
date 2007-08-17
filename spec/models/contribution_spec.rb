require File.dirname(__FILE__) + '/../spec_helper'

describe Contribution do
  before(:each) do
    @model = Contribution.new
    @mock_builder = mock("xml builder") 
  end

  it "should be valid" do
    @model.should be_valid
  end
    
  it_should_behave_like "an xml-generating model"

end

describe Contribution, ".to_xml" do
  
  before do
    @mock_builder = mock("xml builder")    
    @mock_builder.stub!(:title)
    @contribution = Contribution.new
  end

  
end
