require File.dirname(__FILE__) + '/../spec_helper'

describe String, 'ordinal_to_number' do

  it 'should convert "Eleventh" to 11' do
    "Eleventh".ordinal_to_number.should == 11
  end

  it 'should convert "Thirteenth" to 13' do
    "Thirteenth".ordinal_to_number.should == 13
  end

  it 'should convert "Sixteenth" to 16' do
    "Sixteenth".ordinal_to_number.should == 16
  end

  it 'should convert "Twenty-sixth" to 26' do
    "Twenty-sixth".ordinal_to_number.should == 26
  end

  it 'should convert "Thirtieth" to 30' do
    "Thirtieth".ordinal_to_number.should == 30
  end

  it 'should convert "Twenty-seventh" to 27' do
    "Twenty-seventh".ordinal_to_number.should == 27
  end

  it 'should convert "1st" to 1' do
    '1st'.ordinal_to_number.should == 1
  end

  it 'should convert "2nd" to 2' do
    '2nd'.ordinal_to_number.should == 2
  end

  it 'should convert "3rd" to 3' do
    '3rd'.ordinal_to_number.should == 3
  end

  it 'should convert "4th" to 4' do
    '4th'.ordinal_to_number.should == 4
  end

  it 'should convert "25th" to 25' do
    '25th'.ordinal_to_number.should == 25
  end
end
