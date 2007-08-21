require File.dirname(__FILE__) + '/../spec_helper'

def mock_contribution_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:<<)
  mock_builder.stub!(:p)
  mock_builder
end

describe Contribution do
  before(:each) do
    @model = Contribution.new
    @mock_builder = mock_contribution_builder
    @model.text = "some text"
  end

  it "should be valid" do
    @model.should be_valid
  end

  it_should_behave_like "an xml-generating model"

end

describe Contribution, ".to_xml" do

  before do
    @contribution = Contribution.new
  end

  it "should have a 'p' tag with the contribution's xml_id as it's id" do
    @contribution.xml_id = "xmlid"
    @contribution.to_xml.should have_tag('p#xmlid')
  end

  it "should render it's text if there is any" do
    @contribution.text = "some text"
    @contribution.to_xml.should match(/some text/)
  end

end

describe Contribution, ".cols" do
  
  it "should return a list of the columns for the contribution" do
    contribution = Contribution.new(:column_range => "2,3,4")
    contribution.cols.should == [2,3,4]
  end

end


describe Contribution, ".image_sources" do
  
  it "should return a list of the image sources for the contribution" do
    contribution = Contribution.new(:image_src_range => "image2,image3,image4")
    contribution.image_sources.should == ["image2", "image3", "image4"]
  end

end
