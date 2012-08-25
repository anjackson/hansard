require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::MembershipParser do
  
  before do 
    @parser = Hansard::MembershipParser.new
  end
  
  describe 'when asked for the last id in a file' do 
    
    before do 
      @person = {}
      @string = "existing content\n"
      @fake_file = StringIO.new(@string, 'a')
      @fake_file.stub!(:readlines).and_return(['a line', '200\t5'])
      @parser.stub!(:open).and_return(@fake_file)
    end
  
    it 'get the value in the first tab-delimited column of the last line of the file' do 
      @parser.last_id(@fake_file).should == 200
    end
  
    it 'should return zero if there are no lines in the file' do 
      @fake_file.stub!(:readlines).and_return([])
      @parser.last_id(@fake_file).should == 0
    end
  end
  
end