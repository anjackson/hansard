require File.dirname(__FILE__) + '/../spec_helper'

describe TimeContribution, ' on creation time field' do

  before(:each) do
    @model = TimeContribution.new({
      :xml_id => '123',
      :column_range => '23',
      :image_src_range => '42'
    })
  end

  def check_time text, expected
    @model.text = text
    @model.valid?.should be_true
    @model.time.should be_an_instance_of(Time)
    @model.time.strftime('%H:%M:%S').should == expected
  end

  it 'should be populated from text "3.30pm"' do
    check_time '3.30pm', '15:30:00'
  end

  it 'should be populated from text "4&#x00B7;28 pm"' do
    check_time '4&#x00B7;28 pm', '16:28:00'
  end

  it 'should be populated from text "6&#x00B7;7 pm"' do
    check_time '6&#x00B7;7 pm', '18:07:00'
  end

  it 'should be populated from text "7 pm"' do
    check_time '7 pm', '19:00:00'
  end

end


describe TimeContribution do

  before(:each) do
    section = mock(Section)
    sitting = mock(HouseOfCommonsSitting)
    @date = Date.new(2007,10,10)

    sitting.stub!(:date).and_return(@date)
    section.stub!(:sitting).and_return(sitting)

    @model = TimeContribution.new({
      :xml_id => '123',
      :column_range => '23',
      :image_src_range => '42'
    })
    @model.stub!(:section).and_return(section)
  end

  def check_timestamp text, expected
    @model.text = text
    @model.valid?.should be_true
    @model.timestamp.should be_an_instance_of(String)
    @model.timestamp.should == expected
  end

  it 'should return ISO timestamp correctly for text "3.30pm"' do
    check_timestamp '3.30pm', "2007-10-10T15:30:00Z"
  end

  it 'should return ISO timestamp correctly for text "4&#x00B7;28 pm"' do
    check_timestamp '4&#x00B7;28 pm', '2007-10-10T16:28:00Z'
  end

  it 'should return ISO timestamp correctly for text "6&#x00B7;7 pm"' do
    check_timestamp '6&#x00B7;7 pm', '2007-10-10T18:07:00Z'
  end

  it 'should return ISO timestamp correctly for text "7 pm"' do
    check_timestamp '7 pm', '2007-10-10T19:00:00Z'
  end
end

