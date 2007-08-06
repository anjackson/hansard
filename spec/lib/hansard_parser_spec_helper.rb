require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/housecommons_parser'

def parse_hansard file
  Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../../data/#{file}").parse
end

describe "All sittings", :shared => true do
  it 'should create sitting with correct type' do
    @sitting.should_not be_nil
    @sitting.should be_an_instance_of(@sitting_type)
  end

  it 'should set sitting date' do
    @sitting.date.should == @sitting_date
  end

  it 'should set sitting date text' do
    @sitting.date_text.should == @sitting_date_text
  end

  it 'should set sitting title' do
    @sitting.title.should == @sitting_title
  end

  it 'should set column of sitting' do
    @sitting.column.should == @sitting_column
  end

  it 'should set sitting opening text, if any' do
    @sitting.text.should == @sitting_text
  end
end

describe "All commons sittings", :shared => true do
  it 'should create debates section' do
    @sitting.debates.should_not be_nil
    @sitting.debates.should be_an_instance_of(DebatesSection)
  end
end
