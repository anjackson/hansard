require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser do

  before(:all) do
    file = 'housecommons_ordered_list_in_section.xml'
    @sitting = Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../data/#{file}", @logger).parse
    @sitting.save!
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it "should have date" do
    @sitting.date.should == Date.new(1980, 5, 1)
  end

  it "should add ordered list in member contribution p element to member contribution text" do
    section = @sitting.debates.sections[0].sections[0]
    section.title.should == 'ROYAL ASSENT'

    section.contributions[0].text.should == ": I have to notify the House, in accordance with the Royal Assent Act 1967...<ol>\n            <li>1. Companies Act 1980.</li>\n          </ol>"
  end
end
