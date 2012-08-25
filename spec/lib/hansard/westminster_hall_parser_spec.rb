require File.dirname(__FILE__) + '/../../spec_helper'


describe Hansard::WestminsterHallParser, "when parsing a Commons writtenstatements file'" do

  before(:all) do
    file = 'westminster_hall_example.xml'
    source_file = mock_model(SourceFile, :volume => mock_model(Volume))
    @sitting = parse_hansard_file Hansard::WestminsterHallParser, data_file_path(file), nil, SourceFile.new
  
    @sitting_type = WestminsterHallSitting
    @sitting_date = Date.new(2003,4,29)
    @sitting_date_text = 'Tuesday 29 April 2003'
    @sitting_title = 'Westminster Hall'
    @sitting_start_column = '1WH'
    @sitting_end_column = '2WH'
    @sitting_chairman = 'SIR NICHOLAS WINTERTON'
    @school_funding_section = @sitting.debates.sections[1]
  end

  it_should_behave_like "All sittings or written answers or written statements"

  it 'should create a Section for each section' do
    @school_funding_section.should be_an_instance_of(Section)
  end

  it 'should create a procedural contribution for a paragraph with no member' do
    procedural = @school_funding_section.contributions[0]
    procedural.should be_an_instance_of(ProceduralContribution)
    procedural.text.should == '<i>Motion made, and Question proposed,</i> That the sitting be now adjourned.&#x2014;<i>[Mr. Sutcliffe.]</i>'
  end

  it 'should create a time contribution for a paragraph containing a time stamp' do
    timestamp = @school_funding_section.contributions[1]
    timestamp.should be_an_instance_of(TimeContribution)
    timestamp.text.should == '9.30 am'
  end

  it 'should create a member contribution for a paragraph with a member' do
    contribution = @school_funding_section.contributions[2]
    contribution.should be_an_instance_of(MemberContribution)
    contribution.member_name.should == 'Mr. Deputy Speaker'
    contribution.text.should == ': I welcome Members to this first sitting of Westminster Hall following the somewhat shortened but none the less very enjoyable Easter recess. I hope that all colleagues are duly refreshed.'
  end
end