require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser do

  class DummyLogger
    attr_reader :text
    def add_log text
      @text = '' unless @text
      @text += text
    end
  end

  before(:all) do
    file = 'housecommons_by_private_order_in_contribution.xml'
    @logger = DummyLogger.new
    @sitting = Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../data/#{file}", @logger).parse
    @sitting.save!
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it "should have date" do
    @sitting.date.should == Date.new(1960, 3, 31)
  end

  it "should set procedural_note on contribution for (<i>by Private Notice</i>) after a member element" do
    section = @sitting.debates.sections[0].sections[0]
    section.title.should == 'UNION OF SOUTH AFRICA (ARRESTED PERSONS)'

    section.contributions.first.text.should == 'asked the Minister of State for Commonwealth Relations how many of the persons detained ...'
    @logger.text.should == nil
    section.contributions.first.procedural_note.should == '(<i>by Private Notice</i>)'
  end

  it "should set procedural_note on contribution for <i>(by Private Notice)</i> after a member element" do
    section = @sitting.debates.sections[0].sections[1]
    section.title.should == 'BECHUANALAND (MR. TAMBO AND MR. SEGAL)'

    section.contributions.first.text.should == "asked the Minister of State for Commonwealth Relations if Her Majesty's Government will grant political asylum to ..."
    section.contributions.first.procedural_note.should == '<i>(by Private Notice)</i>'
  end
end
