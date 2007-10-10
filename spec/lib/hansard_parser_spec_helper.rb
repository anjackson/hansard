require File.dirname(__FILE__) + '/../spec_helper'

def parse_hansard file
  Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../../data/#{file}").parse
end

describe "All sittings or written answers", :shared => true do
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

  it 'should set start column of sitting' do
    @sitting.start_column.should == @sitting_start_column
  end

  it 'should set start image of sitting' do
    @sitting.start_image_src.should == @sitting_start_image
  end

  it 'should set sitting opening text, if any' do
    @sitting.text.should == @sitting_text
  end

end

describe "All sittings", :shared => true do

  it_should_behave_like "All sittings or written answers"

  it 'should create debates section' do
    @sitting.debates.should_not be_nil
    @sitting.debates.should be_an_instance_of(Debates)
  end
end
