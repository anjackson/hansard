require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::LordsParser, 'when complete division table appears before "Lordships divided" text' do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    @sitting_type = HouseOfLordsSitting
    @sitting_date = Date.new(1962,3,14)
    @sitting_date_text = 'Wednesday, 14th March, 1962'
    @sitting_title = 'HOUSE OF LORDS'
    @sitting_start_column = '167'
    @sitting_end_column = '304'
    source_file = SourceFile.new
    file = 'houselords_division_table_before_lordships_divided.xml'
    @sitting = parse_hansard_file Hansard::LordsParser, data_file_path(file)

    @sitting.save!

    @section = @sitting.debates.sections.first
  end

  it_should_behave_like "All sittings"

  it 'should place division placeholder contribution after "Lordships divided"' do
    division_placeholder = @section.contributions[4]
    division_placeholder.should be_an_instance_of(DivisionPlaceholder)
    division = division_placeholder.division
    division.should be_an_instance_of(LordsDivision)
  end

  it 'should place division result procedural contribution after division placeholder' do
    division_placeholder = @section.contributions[4]
    division_placeholder.text.should == %Q|<table type=\"span\">\n<tr>\n<td align=\"center\" colspan=\"3\"><b>CONTENTS</b></td>\n</tr>\n<tr>\n<td>Addison, V.</td>\n<td>Kenswood, L.</td>\n<td>Nathan, L.</td>\n</tr>\n</table>\n<table type=\"span\">\n<tr>\n<td align=\"center\" colspan=\"3\"><b>NOT-CONTENTS</b></td>\n</tr>\n<tr>\n<td>Ailwyn, L.</td>\n<td>Derwent, L.</td>\n<td>Milverton, L.</td>\n</tr>\n</table>\n<p>Resolved in the negative, and Motion disagreed to accordingly.</p>|
    @section.contributions.size.should == 6
  end
end
