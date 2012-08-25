require File.dirname(__FILE__) + '/../spec_helper'

def mock_lords_sitting
  sitting = HouseOfLordsSitting.new(
                        :start_column    => "1",
                        :date            => Date.new(1985, 12, 16),
                        :date_text       => "Monday 16th December 1985")
  sitting.debates = Debates.new
  sitting
end

describe HouseOfLordsSitting, 'creating hansard reference' do
  it 'should create reference correctly' do
    sitting = mock_lords_sitting
    volume = mock_model(Volume, :number => 5)
    sitting.stub!(:volume).and_return volume
    sitting.hansard_reference(1).should == 'HL Deb 16 December 1985 vol 5 c1'
  end

end

describe HouseOfLordsSitting, 'the class' do
  it 'should have "Lords" as house' do
    HouseOfLordsSitting.house.should == 'Lords'
  end
end

