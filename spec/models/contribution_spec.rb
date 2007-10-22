require File.dirname(__FILE__) + '/../spec_helper'

def mock_contribution_builder
  mock_builder = mock("xml builder")
  mock_builder.stub!(:<<)
  mock_builder.stub!(:p)
  mock_builder
end

describe Contribution do
  before(:each) do
    section = mock(Section)
    @year = 1999
    @date = Date.new(@year,12,31)
    section.stub!(:year).and_return(@year)
    section.stub!(:date).and_return(@date)

    @model = Contribution.new
    @model.stub!(:section).and_return(section)
    @mock_builder = mock_contribution_builder
    @model.text = "some text"
  end

  it "should be valid" do
    @model.should be_valid
  end

  it "should return year based on parent section's year" do
    @model.year.should == @year
  end

  it "should return date based on parent section's date" do
    @model.date.should == @date
  end

  it_should_behave_like "an xml-generating model"

end

describe Contribution, ".to_xml" do

  before do
    @contribution = Contribution.new
  end

  it_should_behave_like "a contribution"

end

describe Contribution, ".cols" do

  it "should return a list of the columns for the contribution" do
    contribution = Contribution.new(:column_range => "2,3,4")
    contribution.cols.should == [2,3,4]
  end

end

describe Contribution, ".first_col" do

  it "should return the first column" do
    contribution = Contribution.new(:column_range => "2,3,4")
    contribution.first_col.should == 2
  end

  it "should return nil if the contribution has no columns" do
    contribution = Contribution.new(:column_range => nil)
    contribution.first_col.should be_nil
  end

end

describe Contribution, ".last_col" do

  it "should return the last column" do
    contribution = Contribution.new(:column_range => "2,3,4")
    contribution.last_col.should == 4
  end

  it "should return nil if the contribution has no columns" do
    contribution = Contribution.new(:column_range => nil)
    contribution.last_col.should be_nil
  end

end

describe Contribution, ".image_sources" do

  it "should return a list of the image sources for the contribution" do
    contribution = Contribution.new(:image_src_range => "image2,image3,image4")
    contribution.image_sources.should == ["image2", "image3", "image4"]
  end

end

describe Contribution, ".first_image_source" do

  it "should return the first image source " do
    contribution = Contribution.new(:image_src_range => "image2,image3,image4")
    contribution.first_image_source.should == "image2"
  end

  it "should return nil if the contribution has no image sources" do
    contribution = Contribution.new(:image_src_range => nil)
    contribution.first_image_source.should be_nil
  end

end

describe Contribution, ".last_image_source" do

  it "should return the last image source " do
    contribution = Contribution.new(:image_src_range => "image2,image3,image4")
    contribution.last_image_source.should == "image4"
  end

  it "should return nil if the contribution has no image sources" do
    contribution = Contribution.new(:image_src_range => nil)
    contribution.last_image_source.should be_nil
  end

end

