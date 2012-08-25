require File.dirname(__FILE__) + '/../spec_helper'

describe TimeResolver do

  def is_time text, hour, minute=0
    resolver = TimeResolver.new(text)
    resolver.is_time?.should be_true
    resolver.time.hour.should == hour
    resolver.time.min.should == minute
  end

  def is_not_time text
    resolver = TimeResolver.new(text)
    resolver.is_time?.should be_false
    resolver.time.should be_nil
  end

  it 'should make @time nil if @time is a valid time, but throws an exception' do
    Time.stub!(:parse).and_raise Exception.new
    is_not_time '00.00'
  end

  it 'should recognize 00.00 as midnight' do
    is_time '00.00', 0
  end

  it 'should recognize 10.00 as 10am' do
    is_time '10.00', 10
  end

  it 'should recognize 10 00 p.m. as 10pm' do
    is_time '10 00 p.m.', 22
  end

  it 'should recognize 10.00pm as 10pm' do
    is_time '10.00pm', 22
  end

  it 'should recognize 10.00 pm as 10pm' do
    is_time '10.00 pm', 22
  end

  it 'should recognize 10.00 p.m. as 10pm' do
    is_time '10.00 p.m.', 22
  end

  it 'should recognize 10.00 P.M. as 10pm' do
    is_time '10.00 P.M.', 22
  end

  it 'should recognize 10.01am as 10am' do
    is_time '10.01am', 10, 1
  end

  it 'should recognize 10.0 pm as 10pm' do
    is_time '10.0 pm', 22
  end

  it 'should recognize 10.0 p m. as 10pm' do
    is_time '10.0 p m.', 22
  end

  it 'should recognize 10.0. p.m. as 10pm' do
    is_time '10.0. p.m.', 22
  end

  it 'should recognize 10.0p.m. as 10pm' do
    is_time '10.0p.m.', 22
  end

  it 'should recognize 10.12 p.m.] as 10:12pm' do
    is_time '10.12 p.m.]', 22, 12
  end

  it 'should recognize 10.13] p.m. as 10:13pm' do
    is_time '10.13] p.m.', 22, 13
  end

  it 'should recognize 10.16 Pm as 10:16pm' do
    is_time '10.16 Pm', 22, 16
  end

  it 'should recognize 10.16 p.m as 10:16pm' do
    is_time '10.16 p.m', 22, 16
  end

  it 'should recognize 10.37.a.m. as 10:37am' do
    is_time '10.37.a.m.', 10, 37
  end

  it 'should recognize 10.3 p.m. as 10:30pm' do
    is_time '10.3 p.m.', 22, 3
  end

  it 'should not recognize 108.] as a time' do
    is_not_time '108.]'
  end

  it 'should not recognize 110.] as a time' do
    is_not_time '110.]'
  end

  it 'should recognize 11,00 p.m. as 11pm' do
    is_time '11,00 p.m.', 23
  end

  it 'should recognize 11.15 pm> as 11:15pm' do
    is_time '11.15 pm>', 23, 15
  end

  it 'should recognize 11.30 as 11:30am' do
    is_time '11.30', 11, 30
  end

  it 'should recognize 12.00 midnight as 12:00am' do
    is_time '12.00 midnight', 0
    is_time '12 midnight', 0
    is_time '12 midnight.', 0
    is_time '12 Midnight', 0
  end

  it 'should recognize 12.00 m. as 12:00am' do
    is_time '12.00 m.', 0
  end

  it 'should recognize 13.51 p.m. as 1:51pm' do
    is_time '13.51 p.m.', 13, 51
  end

  it 'should recognize 15.43 pm as 3:43pm' do
    is_time '15.43 pm', 15, 43
  end

  it 'should recognize .400p.m. as 4pm' do
    is_time '.400p.m.', 16
  end

  it 'should recognize 4. 01 a. m. as 4:01am' do
    is_time '4. 01 a. m.', 4, 01
  end

  it 'should recognize 7. pm as 7pm' do
    is_time '7. pm', 19
  end

  it 'should recognize 6.43 p.m.6 as 6:43pm' do
    is_time '6.43 p.m.6', 18, 43
  end

  it 'should recognize at 10.15 pm as 10:15pm' do
    is_time 'at 10.15 pm', 22, 15
  end

  it 'should recognize <b>10.2 p.m. as 10:02pm' do
    is_time '<b>10.2 p.m.', 22, 2
  end

  it 'should not recognize Division No. 181] as a time' do
    is_not_time 'Division No. 181]'
  end

  it 'should not recognize <i>See c. as a time' do
    is_not_time '<i>See c.'
  end

  it 'should not recognize <i>Teller as a time' do
    is_not_time '<i>Teller'
  end

  it 'should not recognize No. 109.] as a time' do
    is_not_time 'No. 109.]'
  end

  it 'should not recognize <i>L. President. as a time' do
    is_not_time '<i>L. President.'
  end

end
