require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser do

  before(:all) do
    file = 'housecommons_table_in_section.xml'
    @sitting = Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../data/#{file}", nil).parse
    @sitting.save!
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it "should have date" do
    @sitting.date.should == Date.new(1971, 6, 21)
  end

  it "should create table contribution for table in section element" do
    debates = @sitting.debates

    debates.sections[0].title.should == 'Clause 41'
    section = debates.sections[0].sections.first
    section.title.should == 'APPLICATION OF FOREGOING PROVISIONS TO EXISTING MORTGAGE LOANS'
    section.contributions[0].should be_an_instance_of(ProceduralContribution)
    section.contributions[1].should be_an_instance_of(TableContribution)
    section.contributions[1].text.should == %Q[<table type="span">\n          <tr>\n            <td align="right"><i>Unsecured Loans</i></td>\n            <td></td>\n          </tr>\n        </table>]
  end

end
