require File.dirname(__FILE__) + '/../spec_helper'

describe SourceFile, ', the class' do
  it 'should respond to from_file' do
    lambda {SourceFile.from_file("directory/some.xml")}.should_not raise_error
  end
end

describe SourceFile do

  before(:each) do
    SourceFile.delete_all
  end

  after(:each) do
    SourceFile.delete_all
  end

  it 'should return associated parliament_session' do
    source_file = SourceFile.new
    source_file.save!
    session = ParliamentSession.new :source_file_id => source_file.id
    session.save!

    source_file.parliament_session.should == session

    SourceFile.delete_all
    ParliamentSession.delete_all
  end

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

  it 'should create error summary hash correctly' do
    source_file_x = SourceFile.new :name => 'x'
    source_file_x.add_log 'Bad date format: date format="1980-07-28">Monday 22 July 1980'
    source_file_x.add_log 'Missing column? Got: 593, expected 591 (last column 590)'
    source_file_x.add_log 'Missing or badly formatted session tag'
    source_file_x.save!
    source_file_x.log.should == %Q[Bad date format: date format="1980-07-28">Monday 22 July 1980\nMissing column? Got: 593, expected 591 (last column 590)\nMissing or badly formatted session tag]

    source_file_y = SourceFile.new :name => 'y'
    source_file_y.add_log 'Missing column? Got: 35, expected 34 (last column 33)'
    source_file_y.save!

    source_file_z = SourceFile.new :name => 'z'
    source_file_z.add_log 'Bad date format: date format="1979-11-11">Wednesday 28 November 1979'
    source_file_z.save!

    error_types, hash = SourceFile.get_error_summary
    error_types.size.should == 3

    hash['Bad date format'].should_not be_nil
    hash['Missing column'].should_not be_nil
    hash['Missing or badly formatted session tag'].should_not be_nil

    hash['Bad date format'].size.should == 2
    hash['Missing column'].size.should == 2
    hash['Missing or badly formatted session tag'].size.should == 1

    error_types[0].should == 'Bad date format'
    error_types[1].should == 'Missing column'
    error_types[2].should == 'Missing or badly formatted session tag'
  end
end

