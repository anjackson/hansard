require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::ParserTaskHelper do

  before :each do
    self.class.send(:include, Hansard::ParserTaskHelper)
  end

  describe 'when parsing' do 
    
    before do
      @date = mock('date')
      @file = mock 'file'
      @error =  RuntimeError.new('test error')
      @parser_class = mock 'parser_class'
      @source_file = mock 'source_file'
      @data_file = mock('data_file', :saved? => false, 
                                    :name => '', 
                                    :directory => '', 
                                    :source_file= => nil, 
                                    :log= => nil, 
                                    :add_log => nil, 
                                    :attempted_parse= => nil, 
                                    :log_exception => nil)
    end
    
    it 'should find directories matching pattern' do
      path = mock('path')
      Dir.should_receive(:glob).with('pattern').and_return [path]
      File.should_receive(:directory?).with(path).and_return true
      directories('pattern').should == [path]
    end

    it 'should set the attempted parse flag on the data file to true' do 
      @data_file.should_receive(:attempted_parse=).with true
      parse_via_data_file @file, @data_file, @parser_class, @source_file
    end
    
    it 'should log a division parsing exception raised when parsing with division parsing on' do 
      stub!(:try_parse).with(@file, @data_file, @source_file, @parser_class).and_raise(Hansard::DivisionParsingException)
      stub!(:try_parse).with(@file, @data_file, @source_file, @parser_class, false)
      @data_file.should_receive(:log_exception)
      parse_via_data_file @file, @data_file, @parser_class, @source_file
    end
    
    it 'should try parse again without division matching if division matching fails' do
      stub!(:try_parse).with(@file, @data_file, @source_file, @parser_class).and_raise(Hansard::DivisionParsingException)
      should_receive(:try_parse).with(@file, @data_file, @source_file, @parser_class, false)
      parse_via_data_file @file, @data_file, @parser_class, @source_file
    end
    
    it 'should log a generic exception raised when parsing with division parsing on' do
      stub!(:try_parse).with(@file, @data_file, @source_file, @parser_class).and_raise(@error)
      @data_file.should_receive(:log_exception).with(@error)
      parse_via_data_file @file, @data_file, @parser_class, @source_file
    end
    
     it 'should log a generic exception raised when parsing with division parsing off' do
       stub!(:try_parse).with(@file, @data_file, @source_file, @parser_class).and_raise(Hansard::DivisionParsingException)
       stub!(:try_parse).with(@file, @data_file, @source_file, @parser_class, false).and_raise(@error)
       @data_file.should_receive(:log_exception).with(@error)
       parse_via_data_file @file, @data_file, @parser_class, @source_file 
     end
    
    it 'should reload Westminster Hall files and Commons files when asked to reload Commons on a provided date' do
      should_receive(:reload_on_date).with(@date, Hansard::ParserTaskHelper::WESTMINSTER_HALL_PATTERN, WestminsterHallSitting, Hansard::WestminsterHallParser)
      should_receive(:reload_on_date).with(@date, Hansard::ParserTaskHelper::COMMONS_PATTERN, HouseOfCommonsSitting, Hansard::CommonsParser)
      reload_commons_on_date(@date)
    end

    it 'should reload Grand Committee and Lords files when asked to reload Lords on a provided date' do
      should_receive(:reload_on_date).with(@date, Hansard::ParserTaskHelper::GRAND_COMMITTEE_PATTERN, GrandCommitteeReportSitting, Hansard::GrandCommitteeReportParser)
      should_receive(:reload_on_date).with(@date, Hansard::ParserTaskHelper::LORDS_PATTERN, HouseOfLordsSitting, Hansard::LordsParser)
      reload_lords_on_date @date
    end

    it 'should reload Lords and Commons Written Answers files when asked to reload Written Answers on a provided date' do
      should_receive(:reload_on_date).with(@date, Hansard::ParserTaskHelper::WRITTEN_PATTERN, WrittenAnswersSitting, Hansard::WrittenAnswersParser).and_return @data_file
      should_receive(:reload_on_date).with(@date, Hansard::ParserTaskHelper::COMMONS_WRITTEN_PATTERN, CommonsWrittenAnswersSitting, Hansard::WrittenAnswersParser).and_return @data_file
      should_receive(:reload_on_date).with(@date, Hansard::ParserTaskHelper::LORDS_WRITTEN_PATTERN, LordsWrittenAnswersSitting, Hansard::WrittenAnswersParser).and_return @data_file
      reload_written_answers_on_date @date
    end

    it 'should not identify "" as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('').should be_false
    end
    
    it 'should identify "MAJORITY." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["MAJORITY."]').should be_true
    end
      
    it 'should identify "List of the Noes." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["List of the Noes."]').should be_true
    end
      
    it 'should identify "List of theNOES." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["List of theNOES."]').should be_true
    end
      
    it 'should identify "List of the AYES." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["List of the AYES."]').should be_true
    end
      
    it 'should identify "LIST OF THE DIVISION." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["LIST OF THE DIVISION."]').should be_true
    end
      
    it 'should identify "List of theMINORITY." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["List of theMINORITY."]').should be_true
    end
      
    it 'should identify "List of theMINORITY." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["List of theMINORITY."]').should be_true
    end
    
    it 'should identify "List to the Minority." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["List to the Minority."]').should be_true
    end
    
    it 'should identify "List of Members who voted in the Minorities." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["List of Members who voted in the Minorities."]').should be_true
    end
    
    it 'should identify "List of the YES:" as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["List of the YES:"]').should be_true
    end
    
    it 'should identify "List of the AYE" as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["List of the AYE"]').should be_true
    end
    
    it 'should identify "List of the AYES." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: [List of the AYES."]').should be_true
    end
    
    it 'should identify "YES." as an old division header' do
      Hansard::ParserTaskHelper.old_division_header?('parsing FAILED unexpected table: ["YES."]').should be_true
    end

  end
  
  describe 'when yielding source files to be processsed' do 

    before do 
      @files = ["#{RAILS_ROOT}/spec/data/xml/S100001P0.xml",
                "#{RAILS_ROOT}/spec/data/xml/S5CV0412P0.xml",
                "#{RAILS_ROOT}/spec/data/xml/S6V00001P0.xml"]
      stub!(:base_path).and_return("#{RAILS_ROOT}/spec/data")
    end
    
    def expect_files total_processes, process_number, expected_files
      files = []
      per_source_file(total_processes, process_number){ |file| files << file }
      files.should == expected_files      
    end
    
    it 'should yield all source files when running with one process' do 
      expect_files(1, 0, @files)
    end

    it 'should yield the first file when running the first process out of three' do 
      expect_files(3, 0, [@files.first])
    end
    
    it 'should yield the first and third file when running the first process out of two' do 
      expect_files(2, 0, [@files.first, @files.last])
    end
    
    it 'should yield the second file when running the second process out of two' do 
      expect_files(2, 1, [@files[1]])
    end
    
  end
  
end