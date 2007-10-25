require File.dirname(__FILE__) + '/../spec_helper'

describe ParliamentSession, 'volume_in_series_to_i' do

  it 'should be able to convert a roman numerial volume_in_series string to an integer' do
    session = ParliamentSession.new :volume_in_series => 'CXXI'
    session.volume_in_series_to_i.should == 121
  end

  it 'should be able to convert an integer volume_in_series string to an integer' do
    session = ParliamentSession.new :volume_in_series => '121'
    session.volume_in_series_to_i.should == 121
  end

  it "should raise exception for a volume_in_series string that doesn't represent a number" do
    session = ParliamentSession.new :volume_in_series => 'ABC'
    lambda { session.volume_in_series_to_i }.should raise_error
  end

  it "should raise exception for a volume_in_series string that is nil" do
    session = ParliamentSession.new :volume_in_series => nil
    lambda { session.volume_in_series_to_i }.should raise_error
  end
end
