require File.dirname(__FILE__) + '/../spec_helper'


describe Sitting do
  before(:each) do
    @sitting = Sitting.new
  end

  it "should be valid" do
    @sitting.should be_valid
  end

end

