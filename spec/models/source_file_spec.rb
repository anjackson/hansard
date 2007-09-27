require File.dirname(__FILE__) + '/../spec_helper'

describe SourceFile, ', the class' do
  it 'should respond to from_file' do
    lambda {SourceFile.from_file("directory/some.xml")}.should_not raise_error
  end
end

describe SourceFile do

  it "should validate the uniqueness of the source file name" do
    source_file = SourceFile.new(:name => "popular_name")
    source_file.save!
    second_source_file = SourceFile.new(:name => "popular_name")
    lambda{ second_source_file.save! }.should raise_error
  end

  it 'should default xsd_validated field to nil' do
    source_file = SourceFile.new
    source_file.valid?.should be_true
    source_file.xsd_validated.should be_nil
  end
end

