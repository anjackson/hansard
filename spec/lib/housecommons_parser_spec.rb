require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser, "when passed housecommons_1985_12_16" do
  before(:all) do
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1985,12,16)
    @sitting_date_text = 'Monday 16 December 1985'
    @sitting_title = 'House of Commons' 
    @sitting_column = '1'
    @sitting_text = %Q[<p id="S6CV0089P0-00360" align="center"><i>The House met at half-past Two o'clock</i></p>]

    @sitting = parse_hansard 's6cv0089p0/housecommons_1985_12_16.xml'
    @sitting.save!
  end
  
  it 'should create first section in debates' do
    section = @sitting.debates.sections.first
    section.should_not be_nil
    section.should be_an_instance_of(ProceduralSection)
  end

  it 'should set text on first section in debates' do
    @sitting.debates.sections.first.text.should == '<p id="S6CV0089P0-00361" align="center">[MR. SPEAKER <i>in the Chair</i>]</p>'
  end

  it 'should set title on first section in debates' do
    @sitting.debates.sections.first.title.should == 'PRAYERS'
  end

  it 'should set column on first section in debates' do
    @sitting.debates.sections.first.column.should == '1'
  end

  it 'should set xml id on first section in debates' do
    @sitting.debates.sections.first.xml_id.should == 'S6CV0089P0-00361'
  end

  it 'should set debates parent on first section in debates' do
    @sitting.debates.sections.first.section_id.should == @sitting.debates.id
    @sitting.debates.sections.first.section.should == @sitting.debates
  end

  it_should_behave_like "All sittings"
  it_should_behave_like "All commons sittings"
end
