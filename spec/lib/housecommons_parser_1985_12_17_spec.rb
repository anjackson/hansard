require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser, "when passed housecommons_1985_12_17.xml" do
  before(:all) do
    @sitting = parse_hansard 's6cv0089p0/housecommons_1985_12_17.xml'
    @sitting.save!

    @contribution = @sitting.debates.sections[10].sections[1].contributions[99]
  end

  it 'should add a procedural note for an italics element after a member element' do
    @contribution.xml_id.should == 'S6CV0089P0-01275' # that's the one!
    @contribution.procedural_note.should == "<i>(seated and covered)</i>"
  end
  
end
