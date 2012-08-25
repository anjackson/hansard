require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::WrittenStatementsParser do

  describe "when the root element of the doc parsed is not 'writtenstatements'" do
    it "should raise an error noting the unrecognised type" do
      parser = Hansard::WrittenStatementsParser.new('')
      parser.should_receive(:load_doc)
      parser.should_receive(:get_root_name).and_return 'unknown_type'
      lambda { parser.parse }.should raise_error(Exception, /unknown_type/)
    end
  end

  describe "when deciding what house a written statements sitting belongs to" do
    it 'should return "commons" if the sitting source file name contains "commons_writtenstatements"' do
      Hansard::WrittenStatementsParser.new('').house('commons_writtenstatements.xml').should == "commons"
    end

    it 'should return "lords" if the sitting source file name contains "lords_writtenstatements"' do
      Hansard::WrittenStatementsParser.new('').house('lords_writtenstatements.xml').should == "lords"
    end
  end

  describe "when creating written statements sittings" do
    def check_statements_sitting_type house, expected
      parser = Hansard::WrittenStatementsParser.new('')
      parser.stub!(:house).and_return(house)
      parser.sitting_type.should == expected
    end

    it 'should create a commons written statement sitting for content from the commons' do
      check_statements_sitting_type 'commons', CommonsWrittenStatementsSitting
    end

    it 'should create a lords written statement sitting for content from the lords' do
      check_statements_sitting_type 'lords', LordsWrittenStatementsSitting
    end

    it 'should create a parent written statement sitting for content missing a house' do
      check_statements_sitting_type nil, WrittenStatementsSitting
    end
  end

  describe "when parsing a Commons writtenstatements file'" do

    before(:all) do
      file = 'commons_writtenstatements_example.xml'
      source_file = mock_model(SourceFile, :volume => mock_model(Volume))
      @sitting = parse_hansard_file(Hansard::WrittenStatementsParser, data_file_path(file), nil, source_file)
      @sitting_type = CommonsWrittenStatementsSitting
      @sitting_date = Date.new(2003,5,7)
      @sitting_date_text = 'Wednesday 7 May 2003'
      @sitting_title = 'Written Ministerial Statements'
      @sitting_start_column = '31WS'
      @sitting_end_column = '31WS'
      @transport_group = @sitting.groups[0]
      @driving_licenses_section = @transport_group.sections.first
    end

    it_should_behave_like "All sittings or written answers or written statements"

    it 'should create a WrittenStatementsGroup for the first section' do
      @transport_group.should_not be_nil
      @transport_group.should be_an_instance_of(WrittenStatementsGroup)
    end

    it 'should return WrittenStatementsBody if get_body_model_class is called' do
      parser = Hansard::WrittenStatementsParser.new ''
      parser.get_body_model_class.should == WrittenStatementsBody
    end

    it 'should set the title on a section if the section has a child title element' do
      @transport_group.title.should == 'TRANSPORT'
    end

    it 'should create a section for a section nested in another section' do
      @driving_licenses_section.should_not be_nil
      @driving_licenses_section.should be_an_instance_of(Section)
    end

    it 'should set the title on a section for a section nested in another section' do
      @driving_licenses_section.title.should == 'Driving Licences'
    end

    it 'should create a WrittenMemberContribution for a paragraph containing a member element' do
      @driving_licenses_section.contributions.first.should be_an_instance_of(WrittenMemberContribution)
    end
  end

  describe "when parsing a Lords writtenstatements file'" do

    before(:all) do
      file = 'lords_writtenstatements_example.xml'

      source_file = mock_model(SourceFile, :volume => mock_model(Volume))
      @sitting = parse_hansard_file(Hansard::WrittenStatementsParser, data_file_path(file), nil, source_file)
  
      @sitting_type = LordsWrittenStatementsSitting
      @sitting_date = Date.new(2004,6,16)
      @sitting_date_text = 'Wednesday 16 June 2004'
      @sitting_title = 'Written Statements'
      @sitting_start_column = 'WS 29'
      @sitting_end_column = 'WS 29'
      @armed_forces_section = @sitting.groups[0].sections.first
      @defence_estates_section = @sitting.groups[1].sections.first
    end
    
    it_should_behave_like "All sittings or written answers or written statements"

    it 'should create a WrittenStatementsGroup for each section with a title and paragraphs' do
      @sitting.groups.size.should == 2
      @armed_forces_section.should_not be_nil
      @armed_forces_section.should be_an_instance_of(Section)
      @defence_estates_section.should_not be_nil
      @defence_estates_section.should be_an_instance_of(Section)
    end

    it 'should not set the title on a WrittenStatementsGroup to be section title' do
      @armed_forces_section.title.should == 'Armed Forces Pension Scheme'
      @defence_estates_section.title.should == 'Defence Estates Corporate Plan: Key Targets 2004&#x2013;05'
    end
  end
  
  describe 'when handling anchor ids' do 

    before do 
      source_file = mock_model(SourceFile, :name => "S6CV0417P1")
      data_file = mock_model(DataFile, :source_file => source_file, 
                                       :name => 'lords_writtenstatements_example.xml')
      @parser = Hansard::WrittenAnswersParser.new(data_file_path(data_file.name), data_file, source_file)
      @parser.stub!(:sitting).and_return(mock_model(Sitting, :data_file => data_file, 
                                                             :type_abbreviation => 'WS',
                                                             :short_date => '20040212'))
    end

    it_should_behave_like "All parsers"
  
  end
end