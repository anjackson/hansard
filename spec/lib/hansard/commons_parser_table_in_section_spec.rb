require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    file = 'housecommons_table_in_section.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file)
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
    section.contributions[1].text.squeeze(' ').should == %Q[<table type="span" id="S5CV0819P0-03317">\n <tr>\n <td align="right"><i>Unsecured Loans</i></td>\n <td></td>\n </tr>\n </table>]
    section.contributions[1].xml_id.should == "S5CV0819P0-03317"
  end

end
