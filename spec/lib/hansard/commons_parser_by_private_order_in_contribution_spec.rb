require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    file = 'housecommons_by_private_order_in_contribution.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), mock_model(DataFile)
  end

  it "should have date" do
    @sitting.date.should == Date.new(1960, 3, 31)
  end

  it "should set procedural_note on contribution for (<i>by Private Notice</i>) after a member element" do
    section = @sitting.debates.sections[0].sections[0]
    section.title.should == 'UNION OF SOUTH AFRICA (ARRESTED PERSONS)'

    section.contributions.first.text.should == 'asked the Minister of State for Commonwealth Relations how many of the persons detained ...'
    section.contributions.first.procedural_note.should == '(<i>by Private Notice</i>)'
  end

  it "should set procedural_note on contribution for <i>(by Private Notice)</i> after a member element" do
    section = @sitting.debates.sections[0].sections[1]
    section.title.should == 'BECHUANALAND (MR. TAMBO AND MR. SEGAL)'

    section.contributions.first.text.should == "asked the Minister of State for Commonwealth Relations if Her Majesty's Government will grant political asylum to ..."
    section.contributions.first.procedural_note.should == '<i>(by Private Notice)</i>'
  end
  
end
