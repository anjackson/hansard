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
  end
  
  it 'should create first section in debates' do
    section = @sitting.debates.sections.first
    section.should_not be_nil
  end

  it_should_behave_like "All sittings"
  it_should_behave_like "All commons sittings"
end
