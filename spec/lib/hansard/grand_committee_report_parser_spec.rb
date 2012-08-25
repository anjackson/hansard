require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::GrandCommitteeReportParser do 
  
  describe "when parsing a grandcommitteereport file'" do

    before(:all) do
      file = 'grand_committee_report_example.xml'

      source_file = mock_model(SourceFile)
      volume = mock_model(Volume)
      source_file.stub!(:volume).and_return volume
      @sitting = parse_hansard_file Hansard::GrandCommitteeReportParser, data_file_path(file), nil, source_file

      @sitting_type = GrandCommitteeReportSitting
      @sitting_date = Date.new(2004,1,13)
      @sitting_date_text = 'Tuesday, 13 January 2004'
      @sitting_title = 'Official Report of the Grand Committee on the Gender Recognition Bill [HL]'
      @sitting_start_column = 'GC 1'
      @sitting_end_column = 'GC 1'
      @sitting_chairman = 'The Deputy Chairman of Committees (Lord Ampthill)'
    end

    it_should_behave_like "All sittings or written answers or written statements"

    it 'should create report with one section' do
      @sitting.section.should be_an_instance_of(Section)
    end

    it 'should set the section title to be the same as the report title' do
      @sitting.section.title.should == @sitting_title
    end

    it 'should set the end column on the section' do
      @sitting.section.end_column.should == @sitting_end_column
    end

  end

  describe 'when parsing a file without a date tag' do 
  
    it 'should extract the date from the first p tag after the title containing a date' do 
      text = "<grandcommitteereport>
      <col>1004</col>
      <image src=\"S5LV0663P0I0594\"/>
      <col>GC 167</col>
      <title>Official Report of the Grand Committee on<lb/>the Pensions Bill </title>
      <section>
      <title>(Second Day)</title>
      <p>Thursday, 8 July 2004.</p>
      <section>
      <title>The Committee met at a quarter past three of the clock.</title>
      <p>[The Deputy Chairman of Committees (Lord Tordoff) in the Chair.]</p>
      </granscommitteereport>"
      doc = Hpricot.XML(text)
      section = mock_model(Section, :null_object => true)
      sitting = mock_model(Sitting, :section => section, 
                                    :null_object => true,
                                    :date => nil)
      parser = Hansard::GrandCommitteeReportParser.new ''
      parser.stub!(:create_section)
      parser.stub!(:handle_section_element_children)
      sitting.should_receive(:date=).with(Date.new(2004, 7, 8))
      parser.handle_grand_committee_report sitting, doc.at('grandcommitteereport')
    end
    
  end
  
end