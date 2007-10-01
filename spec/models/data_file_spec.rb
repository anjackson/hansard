require File.dirname(__FILE__) + '/../spec_helper'

describe DataFile do

  before do
    @data_file = DataFile.new
  end

  it "should respond to 'file'" do
    @data_file.respond_to?("file").should be_true
  end

  it "should be able to return a File object generated from it's directory and name" do
    @data_file.directory = "dir"
    @data_file.name = "file.name"
    File.should_receive(:new).with("dir/file.name").and_return("the file")
    @data_file.file.should == "the file"
  end

  it 'should return reload_possible is true if RAILS_ENV is development' do
    ApplicationController.stub!(:is_production?).and_return(false)
    DataFile.reload_possible?.should be_true
    data_file = DataFile.new :name => 'houselords_1928_05_15.xml'
    data_file.reload_possible?.should be_true
  end

  it 'should return reload_possible is false if RAILS_ENV is development but date is nil' do
    ApplicationController.stub!(:is_production?).and_return(false)
    data_file = DataFile.new :name => 'houselords_junk.xml'
    data_file.reload_possible?.should be_false
  end

  it 'should return reload_possible is false if RAILS_ENV is production' do
    ApplicationController.stub!(:is_production?).and_return(true)
    DataFile.reload_possible?.should be_false
    data_file = DataFile.new
    data_file.reload_possible?.should be_false
  end

  it 'should return date text "1928/05/15" for file houselords_1928_05_15.xml' do
    data_file = DataFile.new :name => 'houselords_1928_05_15.xml'
    data_file.date_text.should == "1928/05/15"
  end

  it 'should return date "1928-05-15" for file houselords_1928_05_15.xml' do
    data_file = DataFile.new :name => 'houselords_1928_05_15.xml'
    data_file.date.should == Date.new(1928,5,15)
  end

  it 'should return nil date for file houselords_junk.xml' do
    data_file = DataFile.new :name => 'houselords_junk.xml'
    data_file.date.should be_nil
  end

  it 'should return nil date for file index.xml' do
    data_file = DataFile.new :name => 'index.xml'
    data_file.date.should be_nil
  end
end
