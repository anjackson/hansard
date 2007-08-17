require File.dirname(__FILE__) + '/../spec_helper'

describe HouseOfCommonsSitting, ', the class' do
  it 'should respond to find_by_date' do
    lambda {HouseOfCommonsSitting.find_by_date('1999-02-08')}.should_not raise_error
  end
end

describe HouseOfCommonsSitting, 'an instance' do

  before do
    @sitting = HouseOfCommonsSitting.new
    @debates = Debates.new
    @sitting.debates = @debates
    @sitting.save!
  end

  after do
    Sitting.delete_all
    Section.delete_all
  end

  it 'should have debates' do
    @sitting.debates.should_not be_nil
    @sitting.debates.should be_an_instance_of(Debates)
  end
  
end

describe Sitting do
  before(:each) do
    @sitting = Sitting.new
  end

  it "should be valid" do
    @sitting.should be_valid
  end

end

