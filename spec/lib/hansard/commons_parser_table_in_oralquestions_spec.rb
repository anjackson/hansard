require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    file = 'housecommons_table_in_oralquestions.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file)
    @sitting.save!
  end
  
  it "should have date" do
    @sitting.date.should == Date.new(1979,12,18)
  end

  it "should create table contribution for table in p element in section element" do
    debates = @sitting.debates

    debates.sections[0].title.should == 'ORAL ANSWERS TO QUESTIONS'
    section = debates.sections[0].sections[0]
    section.title.should == 'EDUCATION AND SCIENCE'

    section = debates.sections[0].sections[0].sections[0]
    section.title.should == 'Nursery Schools'

    table = section.contributions[0]
    table.should be_an_instance_of(TableContribution)
    table.xml_id.should == 'S5CV0976P1-01073'
    table.column_range.should == "274"
    table.text.should == %Q[<table>\n              <tr>\n                <td align="right" colspan="7">JANUARY 1979</td>\n              </tr>\n              <tr>\n                <td>\n                  <i>Local Education Authority</i>\n                </td>\n              </tr>\n            </table>]
  end

  it "should create table contribution for table element in section element" do
    debates = @sitting.debates

    section = debates.sections[0].sections[0].sections[0]

    continue_table = section.contributions[1]
    continue_table.should be_an_instance_of(TableContribution)
    continue_table.column_range.should == '275'
    continue_table.text.should == %Q[<table>\n            <tr>\n              <td colspan="3">\n                <i>Local Education Authority&#x2014;cont.</i>\n              </td>\n              <td align="right">\n                <i>per cent.</i>\n              </td>\n            </tr>\n          </table>]
  end
end
