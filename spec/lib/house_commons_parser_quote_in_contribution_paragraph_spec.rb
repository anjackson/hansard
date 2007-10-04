require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser do

  before(:all) do
    file = 'housecommons_quote_in_contribution_paragraph.xml'
    @sitting = Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../data/#{file}", @logger).parse
    @sitting.save!
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it "should have date" do
    @sitting.date.should == Date.new(1974, 2, 8)
  end

  it "should create quote contribution for quote elements in member contribution paragraph element" do
    section = @sitting.debates.sections[0].sections[0]
    section.title.should == 'EMERGENCY POWERS'

    section.contributions[0].text.should == "<i>Message from Her Majesty</i> [<i>7th February</i>], <i>considered</i>."
    section.contributions[1].text.should == ": The Message from Her Majesty is as follows:"
    section.contributions[2].should be_an_instance_of(QuoteContribution)
    section.contributions[3].should be_an_instance_of(QuoteContribution)

    section.contributions[2].text.should == 'The Emergency Powers Act 1920, as amended by the Emergency Powers Act 1964 ...'
    section.contributions[3].text.should == 'We, Councellors of State, to whom have been delegated certain Royal Functions ...'
  end

end
