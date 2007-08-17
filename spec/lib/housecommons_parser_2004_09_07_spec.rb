require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser, "when passed housecommons_2004_09_07.xml" do
  before(:all) do
    @sitting = parse_hansard 's6cv0424p1/housecommons_2004_09_07.xml'
    @sitting.save!

    @section = @sitting.debates.sections[1].sections[0]
  end

  it "should add an introduction procedural contribution to an oralquestions section that has a 'p' tag within it" do
    @section.title.should == "SCOTLAND"
    @section.introduction.should_not be_nil
    @section.introduction.should be_an_instance_of(ProceduralContribution)
    @section.introduction.text.should == "<i>The Secretary of State was asked</i>&#x2014;"
  end
  
end
