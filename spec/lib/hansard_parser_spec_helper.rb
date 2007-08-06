require File.dirname(__FILE__) + '/../spec_helper'
require File.dirname(__FILE__) + '/../../lib/housecommons_parser'

def parse_hansard file
  Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../../data/#{file}").parse
end

describe "All sittings", :shared => true do
  it 'should create sitting with correct type' do
    @sitting.should be_an_instance_of(@sitting_type)
  end

  it 'should set date' do
    @sitting.date.should == @sitting_date
  end

  it 'should set date text' do
    @sitting.date_text.should == @sitting_date_text
  end

  it 'should set title' do
    @sitting.title.should == @sitting_title
  end

  it 'should set column' do
    @sitting.column.should == @sitting_column
  end

  it 'should set text, if any' do
    @sitting.text.should == @sitting_text
  end
end

