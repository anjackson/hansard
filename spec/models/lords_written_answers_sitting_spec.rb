require File.dirname(__FILE__) + '/../spec_helper'

describe LordsWrittenAnswersSitting, 'creating hansard reference' do

  it 'should create reference correctly' do
    volume = mock_model(Volume, :number => 5)
    sitting = LordsWrittenAnswersSitting.new(
                          :start_column    => "1",
                          :date            => Date.new(1985, 12, 16),
                          :date_text       => "Monday 16th December 1985",
                          :volume          => volume)
    sitting.hansard_reference(1).should == 'HL Deb 16 December 1985 vol 5 c1WA'
  end

end

describe LordsWrittenAnswersSitting, 'the class' do

  it 'should have "Lords" as house' do
    LordsWrittenAnswersSitting.house.should == 'Lords'
  end

end
