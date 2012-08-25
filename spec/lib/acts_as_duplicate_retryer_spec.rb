require File.dirname(__FILE__) + '/../spec_helper'


DUPLICATE_ERROR = "MySQL::Error: 'Duplicate entry '10122'"

class MockModel
  
  def self.create(attributes, &block)    
    block.call
  end

  def self.logger
    @logger ||= Logger.new(nil)
  end
  
  def self.find(finder_type, options)
  end
  
  include Acts::DuplicateRetryer

end


describe 'A model that acts as a duplicate retryer' do 
  
  before do 
    MockModel.send(:acts_as_duplicate_retryer, :unique_fields => [:name])
  end
  
  it 'should not produce errors when the create call is successful' do 
    MockModel.create(:name => 'a test name'){ :success }.should == :success
  end
  
  it 'should not produce errors if the create call throws a duplicate entry error and there is a model in the db for the unique field values' do 
    lambda do
      MockModel.stub!(:find).and_return('a model')
      MockModel.create(:name => 'a test name') do
        raise(ActiveRecord::StatementInvalid, DUPLICATE_ERROR) 
      end
    end.should_not raise_error
  end
  
  it 'should raise an error if the create call throws a duplicate entry error more than once' do 
    errors = [ActiveRecord::StatementInvalid, DUPLICATE_ERROR] * 2 
    lambda do 
      MockModel.create(:name => 'a test name') do 
        raise errors.shift unless errors.empty?; :success
      end
    end.should raise_error(ActiveRecord::StatementInvalid)
  end
  
  it 'should raise an error if the create call throws a Statement Invalid error that is not a duplicate key erro' do
    lambda do 
      MockModel.create(:name => 'a test name') do 
        raise(ActiveRecord::StatementInvalid, "something else")
      end
    end.should raise_error(ActiveRecord::StatementInvalid, "something else")
  end
  
  it 'should raise an error if the create call throws an error that is not a Statement Invalid error' do 
    lambda do
      MockModel.create(:name => 'a test name') do 
        raise(RuntimeError)
      end
    end.should raise_error(RuntimeError)
  end
  
end