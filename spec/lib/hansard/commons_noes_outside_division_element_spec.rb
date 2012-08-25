require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1932, 6, 7)
    @sitting_date_text = 'Tuesday, 7th June, 1932.'
    @sitting_title = 'HOUSE OF COMMONS.'
    @sitting_start_column = '1777'
    @sitting_end_column = '1777'
    @sitting_chairman = 'Mr. SPEAKER'
    file = 'housecommons_noes_outside_division_element.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), nil, mock_model(SourceFile, :volume => mock_model(Volume), :series_number=>5)

    @sitting.save!

    @first_section = @sitting.debates.sections.first
    @division_placeholder = @first_section.contributions[2]
    @division = @division_placeholder.division
  end

  it_should_behave_like "All sittings"

  it 'should not create division placeholder for division element that occurs prior to the "The House divided" text' do
    @contribution_following_division_start.should_not be_an_instance_of(DivisionPlaceholder)
  end

  it 'should create division placeholder contribution for division element with continuation of ayes table' do
    @division_placeholder.should be_an_instance_of(DivisionPlaceholder)
  end

  it 'should create division for division element with start of ayes table' do
    @division.should be_an_instance_of(CommonsDivision)
  end

  it 'should create division name' do
    @division.name.should == 'Division No. 214.]'
  end

  it 'should create division time text' do
    @division.time_text.should == '[3.33 p. m.'
  end

  it 'should create division time' do
    @division.time.hour.should == 15 # [3.33 p. m.
    @division.time.min.should == 33
  end

  it 'should create aye vote' do
    @division.votes[0].should_not be_nil
    @division.votes[0].should be_an_instance_of(AyeVote)
  end

  it 'should set aye vote name' do
    @division.votes[0].name.should == 'Kerr, Hamilton W.'
  end

  it 'should set aye vote column' do
    @division.votes[0].column.should == '1777'
  end

  it 'should reuse previously created division for continuation of ayes table' do
    @division_placeholder.division.should == @division
  end

  it 'should create teller aye votes for the cells that appear below the cell containing the heading "Tellers for the Ayes"' do
    @division.aye_teller_votes.size.should == 2
    @division.aye_teller_votes[0].name.should == 'Sir Frederick Thomson'
    @division.aye_teller_votes[1].name.should == 'Lord Erskine'
  end

  it 'should create teller noe votes for the cells that appear below the cell containing the heading "Tellers for the Noes"' do
    @division.noe_teller_votes.size.should == 2

    @division.noe_teller_votes[0].name.should == 'Mr. John'
    @division.noe_teller_votes[1].name.should == 'Mr. Groves'
  end

  it 'should have name correct on last aye vote' do
    @division.aye_votes.last.name.should == 'Ramsay, Capt. A. H. M.'
  end

  it 'should set complete division text on the single placeholder contribution' do
    @division_placeholder.text.should == %Q|<table>
  <tr><td align="center"><b>Division No. 214.]</b></td><td align="center"><b>AYES.</b></td><td align="right"><b>[3.33 p. m.</b></td></tr>
  <tr><td>Kerr, Hamilton W.</td><td>Procter, Major Henry Adam</td><td>TELLERS FOR THE AYES.&#x2014;</td></tr>
  <tr><td>Knatchbull, Captain Hon. M. H. R.</td><td>Pybus, Percy John</td><td>Sir Frederick Thomson and Lord</td></tr>
  <tr><td>Knebworth, Viscount</td><td>Raikes, Henry V. A. M.</td><td>Erskine.</td></tr>
  <tr><td>Knight, Holford</td><td>Ramsay, Capt. A. H. M. (Midlothian)</td><td></td></tr>


  <tr><td align=\"center\" colspan=\"3\">NOES</td></tr>
  <tr><td>Lunn, William</td><td>Price, Gabriel</td><td>TELLERS FOR THE NOES.&#x2014;</td></tr>
  <tr><td>Macdonald, Gordon (Ince)</td><td>Thorne, William James</td><td>Mr. John and Mr. Groves.</td></tr>
</table>|
  end
end
