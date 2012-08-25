require File.dirname(__FILE__) + '/../spec_helper'

describe ParserRun, 'when asked for the latest' do
  
  it 'should ask for the most recent parser run' do 
    ParserRun.should_receive(:find).with(:first, :order => 'created_at desc')
    ParserRun.latest
  end
  
  it 'should return "(not recorded)" if there is no parser run' do 
    ParserRun.stub!(:find).and_return(nil)
    ParserRun.latest.should == '(not recorded)'
  end
  
  it 'should return the date of the parser run formatted like "September 15th, 2008" if there is one' do 
    ParserRun.stub!(:find).and_return(ParserRun.new(:created_at => Date.new(2008, 9, 15)))
    ParserRun.latest.should == 'September 15th, 2008'
  end
  
end