require File.dirname(__FILE__) + '/../spec_helper'

describe Sitting do

  before(:each) do
    @sitting = Sitting.new
  end

  it "should be valid" do
    @sitting.should be_valid
  end

end

describe Sitting, ".first_image_source" do

  it "should return the first image source " do
    sitting = Sitting.new(:start_image_src => "image2")
    sitting.first_image_source.should == "image2"
  end

  it "should return nil if the sitting has no image sources" do
    sitting = Sitting.new(:start_image_src => nil)
    sitting.first_image_source.should be_nil
  end

end

