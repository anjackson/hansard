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
    @validation_error = %q[/home/e/apps/uk/hansard/xml_new/test.xml:4: element titlepages: Schemas validity error : Element 'titlepages': This element is not expected. Expected is ( titlepage ). /home/e/apps/uk/hansard/xml_new/test.xml fails to validate]
    splitter.should_receive(:validate_schema).with('hansard_v7.xsd','valid_complete_file').and_return(@validation_error)
    @source_files = splitter.split(path)
    @source_file = @source_files.first
  end

  it 'should add 1 log message with validation error text' do
    @source_file.log_line_count.should == 1
    @source_file.log.should == 'Schema validation failed: ' + @validation_error
  end

  it 'should have xsd_validated field set to false' do
    @source_file.xsd_validated.should be_false
  end

  after(:all) do
    SourceFile.delete_all
  end
end

describe Hansard::Splitter, " when splitting file that has date text in 'From Minutes of' format" do

  before(:all) do
    splitter = Hansard::Splitter.new(false, overwrite=true, verbose=false)
    path = File.join(File.dirname(__FILE__),'..','data','from_minutes_of_date')
    @source_files = splitter.split(path)
    @source_file = @source_files.first
  end

  it 'should accept that 1922-05-09 is valid date for "[From Minutes of May 9.]"' do
    @source_file.log_line_count.should == 1
    @source_file.log.should == "Missing or badly formatted session tag"
  end

  after(:all) do
    SourceFile.delete_all
  end
end

describe Hansard::Splitter, " when splitting file that has division table with no AYES heading" do

  before(:all) do
    splitter = Hansard::Splitter.new(false, overwrite=true, verbose=false)
    path = File.join(File.dirname(__FILE__),'..','data','division_without_ayes_heading')

    # stub the schema check method
    splitter.should_receive(:validate_schema).with('hansard_v7.xsd','division_without_ayes_heading').and_return('')
    @source_files = splitter.split(path)
    @source_file = @source_files.first
  end

  it 'should add error log line about division not having AYES heading' do
    @source_file.log.should == 'Division missing AYES heading'
    @source_file.log_line_count.should == 1
  end

  after(:all) do
    SourceFile.delete_all
  end
end

describe Hansard::Splitter, " when splitting file that has division table in oralquestions section" do

  before(:all) do
    splitter = Hansard::Splitter.new(false, overwrite=true, verbose=false)
    path = File.join(File.dirname(__FILE__),'..','data','division_in_oralquestions')

    # stub the schema check method
    splitter.should_receive(:validate_schema).with('hansard_v7.xsd','division_in_oralquestions').and_return('')
    @source_files = splitter.split(path)
    @source_file = @source_files.first
  end

  it 'should add error log line about division in oralquestions' do
    @source_file.log_line_count.should == 1
    @source_file.log.should == 'Division element inside oralquestion element'
  end

  after(:all) do
    SourceFile.delete_all
  end
end

describe Hansard::Splitter, ' is_orders_of_the_day?' do

  it 'should return true if passed <title>Orders of the Week</title>' do
    Hansard::Splitter.is_orders_of_the_day?("<title>Orders of the Week</title>").should be_false
  end

  it 'should return true if passed <title>Orders of the Day</title>' do
    Hansard::Splitter.is_orders_of_the_day?("<title>Orders of the Day</title>").should be_true
  end

  it 'should return true if passed <title>ORDERS OF THE DAY</title>' do
    Hansard::Splitter.is_orders_of_the_day?("<title>ORDERS OF THE DAY</title>").should be_true
  end

  it 'should return true if passed <title> Orders of the Day</title>' do
    Hansard::Splitter.is_orders_of_the_day?("<title> Orders of the Day</title>").should be_true
  end

  it 'should return true if passed <title>ORDERS OF THE DAY OVERSEAS DEVELOPMENT AND CO-OPERATION BILL [Lords]</title>' do
    Hansard::Splitter.is_orders_of_the_day?("<title>ORDERS OF THE DAY OVERSEAS DEVELOPMENT AND CO-OPERATION BILL [Lords]</title>").should be_true
  end

  it 'should return true if passed <section><title>ORDERS OF THE DAY SUPPLY</title>' do
    Hansard::Splitter.is_orders_of_the_day?("<section><title>ORDERS OF THE DAY SUPPLY</title>").should be_true
  end

  it 'should return true if passed <title>ORDERS OF THE DAY<lb/> SUPPLY</title>' do
    Hansard::Splitter.is_orders_of_the_day?("<title>ORDERS OF THE DAY<lb/> SUPPLY</title>").should be_true
  end

end


describe Hansard::Splitter, " when splitting file that has <title>BUSINESS OF THE HOUSE</title> in oralquestions section" do

  before(:all) do
    splitter = Hansard::Splitter.new(false, overwrite=true, verbose=false)
    path = File.join(File.dirname(__FILE__),'..','data','business_of_the_house_in_oralquestions')

    # stub the schema check method
    splitter.should_receive(:validate_schema).with('hansard_v7.xsd','business_of_the_house_in_oralquestions').and_return('')
    @source_files = splitter.split(path)
    @source_file = @source_files.first
  end

  it 'should add error log line about BUSINESS OF THE HOUSE in oralquestions' do
    @source_file.log.should == "Business of the House title in oralquestions\nOrders of the Day title in oralquestions"
    @source_file.log_line_count.should == 2
  end

  after(:all) do
    SourceFile.delete_all
  end
end


describe Hansard::Splitter, " when splitting file that has <title>ORDERS OF THE DAY</title> in oralquestions section" do

  before(:all) do
    splitter = Hansard::Splitter.new(false, overwrite=true, verbose=false)
    path = File.join(File.dirname(__FILE__),'..','data','orders_of_the_day_inside_oralquestions')

    # stub the schema check method
    splitter.should_receive(:validate_schema).with('hansard_v7.xsd','orders_of_the_day_inside_oralquestions').and_return('')
    @source_files = splitter.split(path)
    @source_file = @source_files.first
  end

  it 'should add error log line about ORDERS OF THE DAY in oralquestions' do
    @source_file.log.should == 'Orders of the Day title in oralquestions'
    @source_file.log_line_count.should == 1
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
    @source_file.log.should match(/Missing image\? Got: 3, expected 2 \(last image 1\)/)
  end

  it "should add a log message about a missing column tag" do
    @source_file.log.should match(/Missing column\? Got: 4, expected 3 \(last column 2\)/)
  end

  it "should not add a log message about a missing column tag in a new section" do
    @source_file.log.should_not match(/Missing column\? Got: 1, expected 5 \(last column 4\)/)
  end

  it "should add a log message if the date is not in correct format - <date format=\"1896-04-09\">Thursday, 9th April 1896.</date>" do
    @source_file.log.should match(/Bad date format: date format="1985-12-16">Monday 17 December 1985<\/date>/)
  end

  it "should add a log message about a missing session tag" do
    @source_file.log.should match(/Missing or badly formatted session tag/)
  end

end
