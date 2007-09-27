require File.dirname(__FILE__) + '/../spec_helper'

describe Hansard::Splitter do

  before do
    @splitter = Hansard::Splitter.new(false, overwrite=true, verbose=false)
    @splitter.stub!(:validate_schema).and_return('')
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

describe Hansard::Splitter, " when splitting file that does not validate against schema" do

  before(:all) do
    splitter = Hansard::Splitter.new(false, overwrite=true, verbose=false)
    path = File.join(File.dirname(__FILE__),'..','data','valid_complete_file')

    # stub the schema check method
    splitter.should_receive(:validate_schema).with('hansard_v7.xsd','valid_complete_file').and_return(%q[/home/e/apps/uk/hansard/xml_new/test.xml:4: element titlepages: Schemas validity error : Element 'titlepages': This element is not expected. Expected is ( titlepage ). /home/e/apps/uk/hansard/xml_new/test.xml fails to validate])
    @source_files = splitter.split(path)
    @source_file = @source_files.first
  end

  it 'should have log_line_count of 1' do
    @source_file.log_line_count.should == 1
  end

  it 'should have xsd_validated field set to false' do
    @source_file.xsd_validated.should be_false
  end

  after(:all) do
    SourceFile.delete_all
  end
end

describe Hansard::Splitter, " when splitting files from spec/data/valid_complete_file" do

  before(:all) do
    splitter = Hansard::Splitter.new(false, overwrite=true, verbose=false)
    splitter.stub!(:validate_schema).and_return('')
    path = File.join(File.dirname(__FILE__),'..','data','valid_complete_file')
    @source_files = splitter.split(path)
    @source_file = @source_files.first
  end

  after(:all) do
    SourceFile.delete_all
  end

  it 'should have xsd_validated field set to true' do
    @source_file.xsd_validated.should be_true
  end

  it "should NOT add a log message about a missing session tag" do
    @source_file.log.should_not match(/Missing or badly formatted session tag/)
  end

  it "should NOT add a log message about a missing titlepage tag" do
    @source_file.log.should_not match(/Missing titlepage tag/)
  end

  it "should NOT add a log message about a broken titlepage tag" do
    @source_file.log.should_not match(/Broken titlepage tag/)
  end

  it "should NOT add log messages about any missing tags" do
    Hansard::Splitter::REQUIRED_TAGS.each do |tag|
      @source_file.log.should_not match(/Missing #{tag} tag/)
    end
  end

  it "should NOT add log messages about any broken tags" do
    Hansard::Splitter::REQUIRED_TAGS.each do |tag|
      @source_file.log.should_not match(/Broken #{tag} tag/)
    end
  end

end

describe Hansard::Splitter, " when splitting files from spec/data/S5LV0436P0" do

  before(:all) do
    splitter = Hansard::Splitter.new(false, overwrite=true, verbose=false)
    splitter.stub!(:validate_schema).and_return('')
    path = File.join(File.dirname(__FILE__),'..','data','S5LV0436P0')
    @source_files = splitter.split(path)
    @source_file = @source_files.first
  end

  after(:all) do
    SourceFile.delete_all
  end

  it "should create a source file model for each file split" do
    @source_files.each{ |file| file.should be_a_kind_of(SourceFile) }
  end

  it "should set the name of the source file model to the name of the source file" do
    @source_file.name.should == "S5LV0436P0"
  end

  it "should set the source file's result directory to the directory containing the split files" do
    @source_file.result_directory.should == "./spec/lib/../data/S5LV0436P0/data/1985_12_16_commons_0.0mb/S5LV0436P0"
  end

  it "should set the source file's schema" do
    @source_file.schema.should == 'hansard_v8.xsd'
  end

  it "should add log messages about each missing tag (except 'titlepage')" do
    Hansard::Splitter::REQUIRED_TAGS.each do |tag|
      @source_file.log.should match(/Missing #{tag} tag/) unless tag == "titlepage"
    end
  end

  it "should add a log message about a broken titlepage tag" do
    @source_file.log.should match(/Broken titlepage tag/)
  end

  it "should add a log message about a missing image tag" do
    @source_file.log.should match(/Missing image\? Got: 3, expected 2 \(last image 1\)\n/)
  end

  it "should add a log message about a missing column tag" do
    @source_file.log.should match(/Missing column\? Got: 4, expected 3 \(last column 2\)\n/)
  end

  it "should not add a log message about a missing column tag in a new section" do
    @source_file.log.should_not match(/Missing column\? Got: 1, expected 5 \(last column 4\)\n/)
  end

  it "should add a log message if the date is not in correct format - <date format=\"1896-04-09\">Thursday, 9th April 1896.</date>" do
    @source_file.log.should match(/Bad date format: date format="1985-12-16">Monday 17 December 1985<\/date>/)
  end

  it "should add a log message about a missing session tag" do
    @source_file.log.should match(/Missing or badly formatted session tag/)
  end

  it "should set the source file's start date text"
  it "should set the source file's end date text"
  it "should set the source file's start date"
  it "should set the source file's end date"

end
