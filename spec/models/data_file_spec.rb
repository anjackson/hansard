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
  
end
