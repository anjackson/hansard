require File.dirname(__FILE__) + '/../spec_helper'

describe DataFile do 
  
  describe 'when creating a model from a file' do 
    
    it 'should set the directory correctly for a directory with multiple segments named "data"' do 
      file = mock('file')
      File.stub!(:basename).with(file).and_return('test name')
      File.stub!(:dirname).with(file).and_return('/data/releases/20081024112328/lib/tasks/../hansard/../../data/1805_01_15_both_3.06mb/S1V0003P0')
      DataFile.should_receive(:find_by_name_and_directory).with('test name', 'data/1805_01_15_both_3.06mb/S1V0003P0')
      DataFile.from_file(file)
    end
  
  end
  
  describe "when asked to log a message" do 
  
    before do 
      @data_file = DataFile.new
      @data_file.stub!(:save!)
      DataFile.stub!(:log_to_stdout)
    end
  
    it "should send a logged message to stdout" do 
      DataFile.should_receive(:log_to_stdout).with("text")
      @data_file.add_log('text')
    end
    
    it 'should append the message to its own log field by default' do 
      @data_file.add_log('text')
      @data_file.log.should == "text\n"
    end
  
    it 'should not append the message to its own log field if asked not to persist the message' do 
      @data_file.add_log('text', persist=false)
      @data_file.log.should == ""
    end
  
    it "should return a log exception string when given an error" do 
      e = Exception.new("a test error")
      backtrace = ['line one', 'line two']
      e.stub!(:backtrace).and_return(backtrace)
      @data_file.log_exception(e)
      @data_file.log.should == "parsing FAILED\ta test error\nline oneline two\n"
    end
  
  end

  describe "when asked for its type of data" do 

    before do
      @data_file = DataFile.new
    end
  
    it 'should return "houselords " for file with name "houselords_1928_05_15.xml"' do 
      @data_file.name = "houselords_1928_05_15.xml"
      @data_file.type_of_data.should == 'houselords '
    end
  
    it 'should return "housecommons " for file with name "housecommons_1928_05_15.xml' do 
      @data_file.name = "housecommons_1928_05_15.xml"
      @data_file.type_of_data.should == 'housecommons '
    end

    it 'should return "header.xml" for file with name "header.xml"' do 
      @data_file.name = 'header.xml'
      @data_file.type_of_data.should == 'header.xml'
    end
  
    it 'should return "grandcommitteereport " for file with name "grandcommitteereport_1928_05_15.xml"' do 
      @data_file.name = 'grandcommitteereport_1928_05_15.xml'
      @data_file.type_of_data.should == 'grandcommitteereport '
    end
  
    it 'should return "wesminsterhall " for file with name "wesminsterhall_1928_05_15.xml"' do 
      @data_file.name = 'wesminsterhall_1928_05_15.xml'
      @data_file.type_of_data.should == 'wesminsterhall '
    end
  
    it 'should return "commons written answers " for file with name "commons_writtenanswers_1928_05_15.xml"' do 
      @data_file.name = 'commons_writtenanswers_1928_05_15.xml'
      @data_file.type_of_data.should == 'commons written answers '
    end
  
  end

  describe "in general" do

    before do
      @data_file = DataFile.new
    end

    it "should respond to 'file'" do
      @data_file.respond_to?("file").should be_true
    end
  
    it "should respond to 'hpricot_doc'" do
      @data_file.respond_to?("hpricot_doc").should be_true
    end
  
    it "should return a Hpricot XML instance when provided with a file path" do 
      file = mock_model(File, :path => "a test path")
      File.stub!(:open).and_return('text')
      Hpricot.should_receive(:XML).with('text')
      data_file = DataFile.new
      data_file.stub!(:file).and_return(file)
      data_file.hpricot_doc
    end
  
    it "should return a data file name from a file name" do 
      @data_file.directory = "test/directory/file.xml"
      @data_file.stripped_name.should == 'file.xml'
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

    it 'should return directory date based on directory name' do
      data_file = DataFile.new :directory => 'data/1969_03_04_lords_3.69mb/S5LV0300P0'
      data_file.directory_date.should == Date.new(1969,3,4)
    end
  
    it 'should return nil if the directory name does not match DATE_PATTERN' do 
      data_file = DataFile.new :directory => 'data/03_04_1969_lords_3.69mb/S5LV0300P0'
      data_file.directory_date.should be_nil
    end
  
    it 'should return nil when asked for a date, with date text string size 10 and where date parsing has failed' do 
      data_file = DataFile.new :name => 'houselords_1928_02_31.xml'
      data_file.date.should be_nil
    end
  
  end

  describe "when updating its counter cache" do 

    it 'should not throw an error if there is no source file' do 
      data_file = DataFile.new
      data_file.update_counter_cache
    end
  
    it 'should not throw an error if the source file has no volume' do 
      data_file = DataFile.new(:source_file => mock_model(SourceFile, :volume => nil))
      data_file.update_counter_cache
    end
   
    it 'should set the volume\'s sittings_tried_count to the number of data files parsed from the source file that were not headers' do 
      volume = mock_model(Volume, :save! => true)
      data_files = mock("data file association")
      data_files.stub!(:count).with(:conditions => ["name != 'header.xml'"]).and_return(4)
      source_file = mock_model(SourceFile, :volume => volume, :data_files => data_files)
      data_file = DataFile.new(:source_file => source_file)
      volume.should_receive(:sittings_tried_count=).with(4)
      data_file.update_counter_cache
    end

  end
  
end

