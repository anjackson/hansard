require File.dirname(__FILE__) + '/../spec_helper'

describe Index, ', the class' do
  it 'should respond to find_by_date_span' do
    lambda {Index.find_by_date_span('1999-02-08', '1999-03-04')}.should_not raise_error
  end
end

describe Index, ".find_by_date_span" do 
  
  before do
    @start_date = Date.new(2007, 1, 1)
    @end_date = Date.new(2007, 6, 6)
  end
  
  it "should return the first index whose start and end dates match those passed" do
    index = Index.create(:start_date => @start_date,
                         :end_date   => @end_date)
    Index.find_by_date_span(@start_date.to_s, @end_date.to_s).should == index
  end
  
end

describe Index, ".entries, when supplied a letter of the alphabet" do
  
  it "should find index entries belonging to the index, and with the correct letter" do
    index = Index.create()
    entries = mock("index entries")
    index.stub!(:index_entries).and_return(entries)
    letter = "F"
    entries.should_receive(:find).with(:all, :conditions => ["letter = ?", letter])
    index.entries("F")
  end

end