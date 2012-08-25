require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1934, 5, 16)
    @sitting_date_text = 'Wednesday, 16th May, 1934.'
    @sitting_title = 'HOUSE OF COMMONS.'
    @sitting_start_column = '1739'
    @sitting_end_column = '1765'
    source_file = SourceFile.new
    @sitting_chairman = 'Mr. SPEAKER'
    file = 'housecommons_division_starting_in_oralquestions.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), nil, source_file
    @division_placeholder = @sitting.debates.sections[1].contributions[2]
  end

  it_should_behave_like "All sittings"

  it 'should not create a division placeholder for division table that starts before "The House divided" text' do
    contribution = @sitting.debates.sections[0].sections[0].contributions[1]
    contribution.should_not be_an_instance_of(DivisionPlaceholder)
  end

  it 'should create division placeholder contribution for division table continuing after "The House divided" text' do
    @division_placeholder.should be_an_instance_of(DivisionPlaceholder)
  end


  it 'should set text correctly on division placeholder contribution for division table continuing after "The House divided" text' do
    @division_placeholder.text.should == %Q|<table>
<tr>
<td align="center">
<b>Division No. 256]</b>
</td>
<td align="center">
<b>AYES.</b>
</td>
<td align="right">
<b>[3.24 p.m.</b>
</td>
</tr>
<tr>
<td>Acland-Troyte, Lieut.-Colonel</td>
<td>Culverwell, Cyril Tom</td>
<td>Hunter, Dr. Joseph (Dumfries)</td>
</tr>


<tr>
<td>Remer, John R.</td>
<td>Storey, Samuel</td>
<td>TELLERS FOR THE AYES.&#x2014;</td>
</tr>
<tr>
<td>Rlckards, George William</td>
<td>Stuart, Lord C. Crichton-</td>
<td>Sir Frederick Thomson and Sir George Penny.</td>
</tr>
<tr>
<td>Roberts, Aled (Wrexham)</td>
<td>Sueter, Rear-Admiral Sir Murray F.</td>
<td></td>
</tr>


<tr>
<td align="center" colspan="3">
<b>NOES.</b>
</td>
</tr>
<tr>
<td>Davies, Rhys John (Westhoughton)</td>
<td>Logan, David Gilbert</td>
<td>TELLERS FOR THE NOES.</td>
</tr>
<tr>
<td>Edwards, Charles</td>
<td>Macdonald, Gordon (Ince)</td>
<td>Mr. John and Mr. D. Graham.</td>
</tr>
</table>|
  end

end
