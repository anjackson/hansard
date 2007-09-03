require File.dirname(__FILE__) + '/../spec_helper'

describe Hansard::Splitter do

  before do
    @splitter = Hansard::Splitter.new(false,false)
  end

  it 'should split commons data with written answers at end' do
    path = File.join(File.dirname(__FILE__),'..','data','splitter_answers_at_end')

    lambda { @splitter.split(path) }.should_not raise_error
  end

  it 'should split commons data with written answers dispersed' do
    path = File.join(File.dirname(__FILE__),'..','data','splitter_answers_dispersed')

    lambda { @splitter.split(path) }.should_not raise_error
  end

  it 'should split commons data with two housecommons sharing the same date' do
    path = File.join(File.dirname(__FILE__),'..','data','splitter_date_repeated')

    lambda { @splitter.split(path) }.should_not raise_error
  end

end
