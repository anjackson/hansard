require File.dirname(__FILE__) + '/../spec_helper'

describe TimeContribution, ' on creation' do

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

  it 'should populate time from text "3.30pm"' do
    check_time '3.30pm', '15:30:00'
  end

  it 'should populate time from text "4&#x00B7;28 pm"' do
    check_time '4&#x00B7;28 pm', '16:28:00'
  end

  it 'should populate time from text "6&#x00B7;7 pm"' do
    check_time '6&#x00B7;7 pm', '18:07:00'
  end

  it 'should populate time from text "7 pm"' do
    check_time '7 pm', '19:00:00'
  end

end
