require File.dirname(__FILE__) + '/../spec_helper'

describe String do

  it 'should return is_arabic_numerial? true for "12"' do
    "12".is_arabic_numerial?.should be_true
  end

  it 'should return is_arabic_numerial? false for "I"' do
    "I".is_arabic_numerial?.should be_false
  end

  it 'should return 1 "1".to_i' do
    "1".to_i.should == 1
  end

  it 'should return 0 for "I".to_i' do
    "I".to_i.should == 0
  end

  it 'should return is_roman_numerial? true for "I"' do
    "I".is_roman_numerial?.should be_true
  end

  it 'should return is_roman_numerial? false for "R"' do
    "R".is_roman_numerial?.should be_false
  end

  it 'should return 1 for "I".roman_to_i' do
    "I".roman_to_i.should == 1
  end

  it 'should raise exception for "R".roman_to_i' do
    lambda {"R".roman_to_i}.should raise_error
  end

  it 'should raise exception for roman numerial string that is greater than maximum number handled by roman_to_i (3999)' do
    lambda {"MMMM".roman_to_i}.should raise_error
  end

  it 'should convert to integer a roman numerial string that is one less than the maximum number handled by roman_to_i (3999)' do
    "MMMCMXCIX".roman_to_i.should == 3999
  end
end
