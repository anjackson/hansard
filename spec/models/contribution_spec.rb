require File.dirname(__FILE__) + '/../spec_helper'

describe Contribution do
  before(:each) do
    @contribution = Contribution.new
  end

  it "should be valid" do
    @contribution.should be_valid
  end
end
