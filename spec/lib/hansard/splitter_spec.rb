require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::Splitter do
  
  before do 
    @splitter = Hansard::Splitter.new(overwrite=true, verbose=false)
    SourceFile.stub!(:log_to_stdout)
  end 

  def do_the_split house, file
    source_file = SourceFile.new(:name => File.basename(file, '.xml'))
    SourceFile.stub!(:find_or_create_by_name).and_return(source_file)
    @splitter.stub!(:house).and_return(house)
    @splitter.stub!(:is_historic_hansard?).and_return true
    @path = data_file_path(file)
    @source_files = @splitter.split(@path)
    @source_file = @source_files.first
    if @source_file.result_directory
      data_file_paths = Dir.glob(File.join(@source_file.result_directory,'*'))
      @data_files = data_file_paths.map{ |path| File.basename(path) }
    end
  end
  
  describe 'idenitifying historic files' do
    
    it 'should identify a historic hansard source files based on the format of its name' do
      @splitter.is_historic_hansard?('S3V0001P0.xml').should be_true
    end

    it 'should identify a modern hansard source file is not a historic source file' do
      @splitter.is_historic_hansard?('CHAN45.xml').should be_false
    end

  end

  describe 'when validating schema' do

    describe 'when source file specifies a schema' do
      
      before do
        @schema = mock('schema')
        @name = mock('name')
        @source_file = mock('source_file', :schema => @schema, :name => @name)
        @splitter.stub!(:source_file).and_return(@source_file)
      end

      it 'should record successful validation' do
        @source_file.should_receive(:xsd_validated=).with(true)
        @splitter.should_receive(:validate_against_schema).with(@schema, @name).and_return nil
        @splitter.validate_schema
      end

      it 'should record failed validation' do
        @source_file.should_receive(:xsd_validated=).with(false)
        @splitter.should_receive(:validate_against_schema).with(@schema, @name).and_return 'error'
        @splitter.should_receive(:add_log).with('Schema validation failed: error')
        @splitter.validate_schema
      end
      
    end

    describe 'when source file does not specify a schema' do
      
      it 'should not validate against schema' do
        source_file = mock('source_file', :schema => nil)
        @splitter.should_receive(:source_file).and_return(source_file)
        @splitter.should_not_receive(:validate_against_schema)
        @splitter.validate_schema
      end
      
    end
  end

  describe "generally" do

    before do
      @splitter.stub!(:house).and_return 'commons'
      @splitter.stub!(:is_historic_hansard?).and_return true
      @splitter.stub!(:validate_schema).and_return ''
    end

    it 'should split and return the input file, given a base path and input file' do
      base_path = 'base_path'
      input_file = 'input_file'
      @splitter.should_receive(:reset_data_path).with(base_path)
      @splitter.should_receive(:split_the_file).with(input_file)
      @splitter.split_file base_path, input_file
    end

    it 'should when delete each file in the path ending with ".xml" when clearing a directory, provided with a path, where the file at the path exists and where overwriting is permitted' do
      path = 'path'
      File.should_receive(:exists?).with(path).and_return true
      file = mock('file')
      files = mock('files')
      Dir.should_receive(:glob).with('path/*.xml').and_return files
      files.should_receive(:each).and_yield file
      File.should_receive(:delete).with(file)
      @splitter.clear_directory path
    end

    it 'should for write to file where outside_buffer is not empty' do
      line = 'line'
      outside_buffer = ['something']
      outside_section_name = 'name'
      outside_date = mock('date')
      @splitter.stub!(:outside_section_name).and_return outside_section_name
      @splitter.stub!(:outside_date).and_return outside_date
      @splitter.stub!(:outside_buffer).and_return outside_buffer
      @splitter.stub!(:section_name).and_return nil
      outside_buffer.should_receive('<<'.to_sym).with(line)
      @splitter.should_receive(:write_to_file).with(anything, outside_buffer, anything)
      @splitter.handle_section_end line
    end

    it 'should log line count mismatch, if line count does not match total lines' do
      source_file = mock('source_file')
      source_file.should_receive(:add_log)
      @splitter.stub!(:source_file).and_return source_file
      @splitter.check_for_line_mismatch(100,101)
    end

    it 'should not log line count mismatch, if line count does not match total lines' do
      source_file = mock('source_file')
      source_file.should_not_receive(:add_log)
      @splitter.stub!(:source_file).and_return source_file
      @splitter.check_for_line_mismatch(100,100)
    end

    it 'should split commons data with written answers at end' do
      path = data_file_path('splitter_answers_at_end')
      @splitter.split(path)
      lambda { @splitter.split(path) }.should_not raise_error
    end

    it 'should split commons data with written answers dispersed' do
      path = data_file_path('splitter_answers_dispersed')
      lambda { @splitter.split(path) }.should_not raise_error
    end

    it 'should split commons data with two housecommons sharing the same date' do
      path = data_file_path('splitter_date_repeated')
      lambda { @splitter.split(path) }.should_not raise_error
    end

  end

  describe "when determining house from input files" do

    it 'should recognize an input file from the lords' do
      path = data_file_path('S5LV0436P0')
      @splitter.house(path).should == "lords"
    end

    it 'should recognize an input file from the commons' do
      path = data_file_path('S6CV0424P1')
      @splitter.house(path).should == "commons"
    end

    it 'should return nil if the house is not indicated in the filename' do
      path = data_file_path('S3V0296P0')
      @splitter.house(path).should == nil
    end

  end
  
  describe 'when handling a line ' do 
  
    before do
      @splitter.buffer = []
      @splitter.index = 1
      @splitter.stub!(:check_line)
      @splitter.column_num = 3
      @splitter.directory_name = 'S5CV0052P0'
      @splitter.image_string = '0110'
      @splitter.image_pattern = /image src="S5CV0052P0I(\d\d\d\d)"\//
      @splitter.lines = ["<housecommons>\n", 
                         "<image src=\"S5CV0052P0I0110\"/>\n",
                         "<col>211</col>\n"]
    end
    
    it 'should increment the line index for a non-proxy line' do 
      @splitter.handle_line(@splitter.lines.first, proxy=false)
      @splitter.index.should == 2
    end
    
    it 'should not increment the line index for a proxy line' do 
      @splitter.handle_line(@splitter.lines.first, proxy=true)
      @splitter.index.should == 1
    end
    
    describe 'when adding missing section tags' do 
      
      it 'should not add a column and image tag if they exist after the section start' do          
        @splitter.add_missing_tags_to_section_start([]).should == []
      end
      
      it 'should not add a column and image tag if they exist after the section start and a date tag' do 
        @splitter.lines = ["<houselords>\n", 
                           "<title>House of Lords</title>\n",
                           "<date format=\"1982-06-07\">Monday, 7th June, 1982.</date>\n",
                           "<image src=\"S5CV0052P0I0110\"/>\n",
                           "<col>1</col>\n"]
        @splitter.add_missing_tags_to_section_start([]).should == []                   
      end
      
      it 'should not add a column when a column with a suffix is already present' do
        @splitter.lines = ["<housecommons>\n", 
                           "<image src=\"S5CV0052P0I0110\"/>\n",
                           "<col>81WS</col>\n"]
        @splitter.add_missing_tags_to_section_start([]).should == []
      end

      it 'should add a column and image tag if they do not exist a line after the section start' do 
        @splitter.lines = ["<housecommons>\n", 
                           "<title>HOUSE OF COMMONS.</title>\n",
                           "<date format=\"1805-03-13\">Wednesday, March 13.</date>\n"]           
        @splitter.add_missing_tags_to_section_start([]).should == ["<image src=\"S5CV0052P0I0110\"/>\n",
                                                                   "<col>3</col>\n"]
      end
    
    end
    
  end
  
  describe 'when checking for a missing image tag' do 
    
    before do 
      @splitter.image_num = 109
      @splitter.stub!(:add_log)
      @splitter.image_pattern = /image src="S5CV0052P0I(\d\d\d\d)"\//
    end
  
    it 'should add a log about an unexpected image if there is one' do 
      @splitter.stub!(:unexpected_image?).and_return(true)
      @splitter.should_receive(:add_log).with("Missing image? Got: 111, expected 110 (last image 109)")
      @splitter.check_for_image('<image src="S5CV0052P0I0111"/>\n')
    end
    
    it 'should set the image number to the number of the found image' do 
      @splitter.check_for_image('<image src="S5CV0052P0I0110"/>\n')
      @splitter.image_num.should == 110
    end
  
    it 'should not add a log if the image is expected' do 
      @splitter.stub!(:unexpected_image?).and_return(false)
      @splitter.should_not_receive(:add_log)
      @splitter.check_for_image('<image src="S5CV0052P0I0110"/>\n')
    end
    
  end
  
  describe 'when checking for a missing column tag' do 
    
    before do 
      @splitter.column_num = 55
      @splitter.stub!(:add_log)
    end
  
    it 'should add a log about an unexpected column if there is one' do 
      @splitter.stub!(:unexpected_column?).and_return(true)
      @splitter.should_receive(:add_log).with("Missing column? Got: 57, expected 56 (last column 55)")
      @splitter.check_for_column('<col>57</col>\n')
    end
    
    it 'should set the image number to the number of the found image' do 
      @splitter.check_for_column('<col>57</col>\n')
      @splitter.column_num.should == 57
    end
  
    it 'should not add a log if the column is expected' do 
      @splitter.stub!(:unexpected_column?).and_return(false)
      @splitter.should_not_receive(:add_log)
      @splitter.check_for_column('<col>57</col>\n')
    end
    
  end
 
  describe 'when asked if an column is unexpected' do 
  
    describe 'if it is a new section' do 
      
      before do 
        @splitter.new_section = true
        @splitter.column_num = 5
      end
      
      it 'should return false if this is a new section and the column is the same as the last column' do 
        @splitter.unexpected_column?(5).should be_false
      end
  
      it 'should return true if the column is more than one greater than the last one and this is a new section' do
        @splitter.unexpected_column?(7).should be_true
      end
      
      it 'should return false if the column number is one' do 
        @splitter.unexpected_column?(1).should be_false
      end
    
    end
    
    describe 'if it is not a new section' do 
      
      before do 
        @splitter.new_section = false
        @splitter.column_num = 5
      end  
        
      it 'should return false if the column is one greater than the last column' do 
        @splitter.unexpected_column?(6).should be_false
      end
    
      it 'should return true if the column is the same as the last one and this is not a new section' do
        @splitter.unexpected_column?(5).should be_true
      end
    
      it 'should return true if the column is more than one greater than the last one and this is not a new section' do
        @splitter.unexpected_column?(7).should be_true
      end
      
    end
    
  end 
  
  describe 'when asked if an image is unexpected' do 
  
    describe 'if it is a new section' do 
      
      before do 
        @splitter.new_section = true
        @splitter.image_num = 5
      end
      
      it 'should return false if this is a new section and the image is the same as the last image' do 
        @splitter.unexpected_image?(5).should be_false
      end
  
      it 'should return true if the image is more than one greater than the last one and this is a new section' do
        @splitter.unexpected_image?(7).should be_true
      end
    
    end
    
    describe 'if it is not a new section' do 
      
      before do 
        @splitter.new_section = false
        @splitter.image_num = 5
      end  
        
      it 'should return false if the image is one greater than the last image' do 
        @splitter.unexpected_image?(6).should be_false
      end
    
      it 'should return true if the image is the same as the last one and this is not a new section' do
        @splitter.unexpected_image?(5).should be_true
      end
    
      it 'should return true if the image is more than one greater than the last one and this is not a new section' do
        @splitter.unexpected_image?(7).should be_true
      end
      
    end
    
  end

  describe "when checking for a session tag" do

    before do
      @source_file = mock_model(SourceFile)
      @splitter.stub!(:source_file).and_return(@source_file)
    end

    it 'should add a log file message if the session tag content is badly formed' do
      @source_file.should_receive(:add_log).with("Badly formatted session tag: this is the session")
      @splitter.check_for_session("<session>this is the session</session>")
    end

    it 'should extract years 1986 and 1987 from the tag <session>1986&#x2013;1987</session>' do
      @splitter.check_for_session("<session>1986&#x2013;1987</session>")
      @splitter.session_start_year.should == 1986
      @splitter.session_end_year.should == 1987
    end

    it 'should extract years 1986 and 1987 from the tag <session>1986&#x2013;87</session>' do
      @splitter.check_for_session("<session>1986&#x2013;87</session>")
      @splitter.session_start_year.should == 1986
      @splitter.session_end_year.should == 1987
    end

    it 'should extract years 1986 and 1986 from the tag <session>1986&#x2013;87</session>' do
      @splitter.check_for_session("<session>1986</session>")
      @splitter.session_start_year.should == 1986
      @splitter.session_end_year.should == 1986
    end

    it 'should extract years 2003 and 2004 from the tag "<session>2003&#x2013;04</session>"' do
      @splitter.check_for_session("<session>2003&#x2013;04</session>")
      @splitter.session_start_year.should == 2003
      @splitter.session_end_year.should == 2004
    end

  end

  describe ' when checking for unlikely dates' do

    before do
      @source_file = mock_model(SourceFile)
      @splitter.stub!(:source_file).and_return(@source_file)
    end

    it 'should log a message about a gap of greater than 90 days between dates' do
      @splitter.dates = [Date.new(1901, 1, 1), Date.new(1901, 6, 30), Date.new(1901, 2, 28)]
      @source_file.should_receive(:add_log).with("Large gap between dates: 1901-02-28 and 1901-06-30")
      @splitter.check_unlikely_dates
    end

    it 'should log a message about dates outside of the range specified in the session tag (if any)' do
      @splitter.dates = [Date.new(1901, 12, 31), Date.new(1902, 1, 1), Date.new(1903, 1, 1) ]
      @splitter.session_start_year = 1902
      @splitter.session_end_year = 1903
      @source_file.stub!(:add_log)
      @source_file.should_receive(:add_log).with("Date not in session years: 1901-12-31")
      @source_file.should_not_receive(:add_log).with("Date not in session years: 1902-01-01")
      @source_file.should_not_receive(:add_log).with("Date not in session years: 1903-01-01")
      @splitter.check_unlikely_dates
    end

  end

  describe "when checking for a date in a line of the file" do

    before do
      @splitter.stub!(:dates).and_return([])
      @source_file = mock_model(SourceFile, :null_object => true)
      @splitter.stub!(:source_file).and_return(@source_file)
    end

    def expect_date(date, line)
      @splitter.check_for_date(line)
      @splitter.date.should == date
    end

    def expect_valid(line)
      @splitter.check_for_date(line)
    end

    it "should use previous date's year if parsed date is after the LAST_DATE" do
      date = LAST_DATE + 1
      @splitter.stub!(:previous_date).and_return mock('date', :year => 1904)
      @splitter.parse_date(date.to_s).should == Date.new(1904, date.month, date.day)
    end

    it 'should recognize 1811-02-22 as a valid date extracted from <date format="1811-02-22">Friday, February 22.</date> as the date parsed by ruby is outside the allowed range' do
      line = '<date format="1811-02-22">Friday, February 22.</date>'
      expect_valid(line)
    end

    it 'should extract the date 1985-12-17 from the line "<date format="1985-12-17">Monday 17 December 1985</date>"' do
      line = '<date format="1985-12-17">Monday 17 December 1985</date>'
      expect_date("1985-12-17", line)
    end

    it 'should recognize 1985-12-17 as a valid date extracted from "Monday 17 December 1985"' do
      line = '<date format="1985-12-17">Monday 17 December 1985</date>'
      expect_valid(line)
    end

    it 'should extract 1922-05-09 from "[From Minutes of May 9.]"' do
      line = '<date format="1922-05-09">[From Minutes of May 9.]</date>'
      expect_date("1922-05-09", line)
    end

    it 'should recognize 1922-05-09 as a valid date extracted from "[From Minutes of May 9.]"' do
      line = '<date format="1922-05-09">[From Minutes of May 9.]</date>'
      expect_valid(line)
    end

    it 'should extract 2004-05-28 from "<date format="2004-05-28">The following answers were received between Friday 28 May and Friday 4 June 2004</date>"' do
      line = '<date format="2004-05-28">The following answers were received between Friday 28 May and Friday 4 June 2004</date>'
      expect_date("2004-05-28", line)
    end

    it 'should extract 2003-04-15 from "<date format=\"2003-04-15\">The following answers were received between 15 and 24 April 2003</date>"' do
      line = '<date format="2003-04-15">The following answers were received between 15 and 24 April 2003</date>'
      expect_date("2003-04-15", line)
    end

    it 'should recognize 2003-04-15 as a valid date extracted from "<date format=\"2003-04-15\">The following answers were received between 15 and 24 April 2003</date>"' do
      line = '<date format="2003-04-15">The following answers were received between 15 and 24 April 2003</date>'
      expect_valid(line)
    end

    it 'should recognize 2004-05-28 as a valid date extracted from "<date format="2004-05-28">The following answers were received between Friday 28 May and Friday 4 June 2004</date>"' do
      line = '<date format="2004-05-28">The following answers were received between Friday 28 May and Friday 4 June 2004</date>'
      expect_valid(line)
    end

    it 'should recognize 1982-11-25 as a valid date extracted from <date format="1982-11-25">Thursday, 25 th November, 1982.</date>' do
      line = '<date format="1982-11-25">Thursday, 25 th November, 1982.</date>'
      expect_valid(line)
    end

    it 'should recognize 1985-12-17 as a valid date extracted from <date format="1985-12-17">Tuesday 1 December 1985</date> as the date indicated in the text is impossible' do
      line = '<date format="1985-12-17">Tuesday 1 December 1985</date>'
      expect_valid(line)
    end

    it 'should extract 1909-04-24 from "<date format="1909-04-24">Wednesday, 24th February, 1909."' do 
      line = '<date format="1909-04-24">Wednesday, 24th February, 1909.'
      expect_date("1909-02-24", line)
    end
    
    it 'should extract 1909-03-04 from "<date format="1909-03-04"/>"' do 
      line = '<date format="1909-03-04"/>'
      expect_date('1909-03-04', line)
    end
    
  end

  describe "when splitting file that has division table in oralquestions section" do

    before do
      do_the_split('commons', 'division_in_oralquestions')
    end

    it 'should add error log line about division in oralquestions' do
      @source_file.log_line_count.should == 1
      @source_file.log.should == 'Division element in oralquestions'
    end

  end

  describe ' is_orders_of_the_day?' do

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

  describe "when splitting file that has <title>BUSINESS OF THE HOUSE</title> in oralquestions section" do

    before do
      do_the_split('commons', 'business_of_the_house_in_oralquestions')
    end

    it 'should add error log line about BUSINESS OF THE HOUSE in oralquestions' do
      @source_file.log.should == "Business of the House title in oralquestions\nOrders of the Day title in oralquestions"
      @source_file.log_line_count.should == 2
    end

  end

  describe "when splitting file that has <title>ORDERS OF THE DAY</title> in oralquestions section" do

    before do
      do_the_split('commons','orders_of_the_day_inside_oralquestions')
    end

    it 'should add error log line about ORDERS OF THE DAY in oralquestions' do
      @source_file.log.should == 'Orders of the Day title in oralquestions'
      @source_file.log_line_count.should == 1
    end

  end

  def expect_data_file(name, expected=true)
    @data_files.include?(name).should == expected
  end

  describe "when creating lords written answers, written statements data files" do

    before do
      do_the_split 'lords', 'houselords_example'
    end

    it 'should create a dated lords written answers file from lords data' do
      expect_data_file('lords_writtenanswers_1909_09_20.xml')
    end

    it 'should create a dated lords written statements file from lords data' do
      expect_data_file('lords_writtenstatements_1909_09_20.xml')
    end
  end

  describe "when creating written answers, written statements data files" do

    before do
      do_the_split 'commons', 'valid_complete_file'
    end

    it 'should create a commons written answers file from commons data' do
      expect_data_file('commons_writtenanswers.xml')
    end

    it 'should create a commons written statements file from commons data' do
      expect_data_file('commons_writtenstatements.xml')
    end

    it 'should create a housecommons file for a housecommons element that only contains "Written Ministerial Statements"' do
      expect_data_file('housecommons_2004_05_10.xml')
    end

  end

  describe "when splitting files from spec/data/valid_complete_file" do

    before do
      do_the_split('commons', 'valid_complete_file')
    end
    
    it "should NOT add a log message about number of lines not matching" do
      @source_file.log.should_not match(/Number of lines don't match/)
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

  describe "when splitting files from spec/data/S5LV0436P0" do

    before do
      do_the_split('commons','S5LV0436P0')
    end

    it "should create a source file model for each file split" do
      @source_files.each{ |file| file.should be_a_kind_of(SourceFile) }
    end

    it "should set the name of the source file model to the name of the source file" do
      @source_file.name.should == "S5LV0436P0"
    end

    it "should set the source file's result directory to the directory containing the split files" do
      @source_file.result_directory.should == "#{RAILS_ROOT}/spec/data/S5LV0436P0/data/1985_12_17_commons_0.0mb/S5LV0436P0"
    end

    it "should set the source file's schema" do
      @source_file.schema.should == 'hansard_v8.xsd'
    end

    it "should add log messages about each missing tag (except 'titlepage' and 'session')" do
      Hansard::Splitter::REQUIRED_TAGS.each do |tag|
        @source_file.log.should match(/Missing #{tag} tag/) unless (tag == "titlepage" or tag == "session")
      end
    end

    it "should add a log message about a badly formatted session tag" do
      @source_file.log.should match(/Badly formatted session tag: During the Third Session of the Second Parliament of the United Kingdom/)
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

    it "should add a log message if the date is not in correct format - <date format=\"1985-12-16\">Tuesday 17 December 1985</date>" do
      @source_file.log.should match(/Bad date format: date format="1985-12-16">Tuesday 17 December 1985<\/date> Suggested date: 1985-12-17/)
    end

    it "should set the start date on the source file to 1985-12-17" do
      @source_file.start_date.should == Date.new(1985, 12, 17)
    end

  end

  describe "when creating a result file path" do

    before do
      do_the_split('lords', 'S5LV0436P0')
    end

    it 'should create a file name with "both" in it for a source file with no house' do
      @splitter.stub!(:house).and_return(nil)
      @splitter.split(@path)
      File.basename(@splitter.result_file_path(@path)).should == '1985_12_17_both_0.0mb'
    end

    it 'should create a file name with "lords" for a source file from the lords' do
      @splitter.stub!(:house).and_return("lords")
      @splitter.split(@path)
      File.basename(@splitter.result_file_path(@path)).should == '1985_12_17_lords_0.0mb'
    end

    it 'should create a file name with "commons" for a source file from the commons' do
      @splitter.stub!(:house).and_return("commons")
      @splitter.split(@path)
      File.basename(@splitter.result_file_path(@path)).should == '1985_12_17_commons_0.0mb'
    end

  end

  describe "when splitting file that has written answers between debates sections" do

    before do
      do_the_split 'commons', 'splitter_writtenanswers_between_debates'
    end

    it 'should create a header, a commons data file and a written answers data file' do
      @data_files.sort.should == ["commons_writtenanswers_1926_03_15.xml", "header.xml", "housecommons_1926_03_15.xml"]
    end

    it 'should create a commons data file that has two debates sections' do
      commons_file = Dir.glob(File.join(@source_file.result_directory,'housecommons_*')).first
      File.read(commons_file).should == %Q|  <housecommons>
    <image src="writtenanswers_between_debatesI0000"/>
    <col>677</col>
    <title/>
    <date format="1926-03-15">Monday, 15th March, 1926.</date>
    <p/>
    <debates>
      <section>
        <title/>
      </section>
      <oralquestions>
        <title/>
        <section>
          <title/>
          <section>
      </section>
        </section>
      </oralquestions>
      <section>
        <title/>
      </section>
    </debates>
    <debates>
      <section>
        <title/>
      </section>
    </debates>
  </housecommons>
|
    end

  end
end