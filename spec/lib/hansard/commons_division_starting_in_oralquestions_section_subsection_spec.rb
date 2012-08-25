require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1933, 6, 21)
    @sitting_date_text = 'Wednesday, 21st June, 1933.'
    @sitting_title = 'HOUSE OF COMMONS.'
    @sitting_chairman = 'Mr. SPEAKER'
    @sitting_start_column = '741'
    @sitting_end_column = '771'
    source_file = SourceFile.new
    file = 'housecommons_division_starting_in_oralquestions_section_subsection.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), nil, source_file

    @sitting.save!

    @division_placeholder = @sitting.debates.sections[1].contributions[2]
  end

  it_should_behave_like "All sittings"

  it 'should not create a division placeholder for division table that starts before "The House divided" text' do
    contribution = @sitting.debates.sections[0].sections[0].sections[0].contributions[3]
    contribution.should_not be_an_instance_of(DivisionPlaceholder)
  end

  it 'should create division placeholder contribution for division table continuing after "The House divided" text' do
    @division_placeholder.should be_an_instance_of(DivisionPlaceholder)
  end

  it 'should set text correctly on division placeholder contribution for division table continuing after "The House divided" text' do
    @division_placeholder.text.should == %Q|<table>
<tr>
<td align="center">
<b>Division No. 232.]</b>
</td>
<td align="center">
<b>AYES.</b>
</td>
<td align="right">
<b>[3.36 p.m.</b>
</td>
</tr>
<tr>
<td>Acland, Rt. Hon. Sir Francis Dyke</td>
<td>Christie, James Archibald</td>
<td>Ersklne, Lord (Weston-super-Mare)</td>
</tr>


<tr>
<td>Manningham-Buller. Lt.-Col. Sir M.</td>
<td>Rutherford, Sir John Hugo (Liverp'l)</td>
<td>
<b>TELLERS FOR THE AYES.&#x2014;</b>
</td>
</tr>
<tr>
<td>Margesson, Capt. Rt. Hon. H. D. R.</td>
<td>Salt. Edward W.</td>
<td>Sir Frederick Thomson and Captain Austin Hudson.</td>
</tr>


<tr>
<td>
<b>NOES.</b>
</td>
</tr>
<tr>
<td>George, Megan A. Lloyd (Anglesea)</td>
<td>Lunn, William</td>
<td>
<b>TELLERS FOR THE NOES.&#x2014;</b>
</td>
</tr>
<tr>
<td></td>
<td></td>
<td>Mr. John and Mr. D. Graham.</td>
</tr>
</table>|
  end

end
