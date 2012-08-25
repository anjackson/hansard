require File.dirname(__FILE__) + '/../spec_helper'

describe WestminsterHallSitting, 'the class' do

  it 'should have "westminster_hall" as uri_component' do
    WestminsterHallSitting.uri_component.should == 'westminster_hall'
  end

  it 'should have "Commons" as house' do
    WestminsterHallSitting.house.should == 'Commons'
  end

  it 'should have HC as reference prefix' do
    WestminsterHallSitting.hansard_reference_prefix.should == 'HC'
  end
end
