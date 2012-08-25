require File.dirname(__FILE__) + '/../spec_helper'

describe "library_office_holders.txt" do

  before do
    @office_holders_txt = './reference_data/commons_library_data/library_office_holders.txt'
    @lines_in_office_holders_txt = File.new(@office_holders_txt)
  end

  it "should exist as a file" do
    File.stat(@office_holders_txt).file?.should == true
  end

  it "should be readable" do
    File.stat(@office_holders_txt).readable?.should == true
  end

  it "should not be zero length" do
    File.stat(@office_holders_txt).zero?.should == false
  end

  it "should have at least four tab separated items on each line" do
    @lines_in_office_holders_txt.each do |line|
      line.split("\t").size.should be > 3
    end
  end

end