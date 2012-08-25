require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::LordsParser do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    @sitting_type = HouseOfLordsSitting
    @sitting_date = Date.new(1909,9,21)
    @sitting_date_text = 'Tuesday, 21st September, 1909.'
    @sitting_title = 'HOUSE OF LORDS.'
    @sitting_start_column = '77'
    @sitting_end_column = '79'
    file = 'houselords_split_division_table.xml'
    @sitting = parse_hansard_file Hansard::LordsParser, data_file_path(file)
    @sitting.save!

    @first_section = @sitting.debates.sections.first
    @contribution_following_division_start = @first_section.contributions[1]
    @division_placeholder = @first_section.contributions[4]
    @division = @division_placeholder.division
  end

  it_should_behave_like "All sittings"

  it 'should have division number as 1 when first division has no number in name' do
    @division.number.should == 1
  end

  it 'should not create division placeholder for division element that occurs prior to the "The House divided" text' do
    @contribution_following_division_start.should_not be_an_instance_of(DivisionPlaceholder)
  end

  it 'should create division placeholder contribution for division element with continuation of contents table' do
    @division_placeholder.should be_an_instance_of(DivisionPlaceholder)
  end

  it 'should create division for division element with start of contents table' do
    @division.should be_an_instance_of(LordsDivision)
  end

  it 'should create division name' do
    @division.name.should be_nil
  end

  it 'should create division time text' do
    @division.time_text.should be_nil
  end

  it 'should create division time' do
    @division.time.should be_nil
  end

  it 'should create content vote' do
    @division.votes[0].should_not be_nil
    @division.votes[0].should be_an_instance_of(ContentVote)
  end

  it 'should set content vote name' do
    @division.votes[0].name.should == 'Norfolk, D. (E. Marshal.)'
    @division.votes[0].constituency.should == nil
  end

  it 'should set content vote column' do
    @division.votes[0].column.should == '77'
  end
  
  it 'should reuse previously created division for continuation of contents table' do
    @division_placeholder.division.should == @division
  end

  it 'should have name correct on last content vote' do
    @division.content_votes.last.name.should == 'Zouche of Haryngworth, L.'
  end

  it 'should create teller content votes for the cells that appear below the cell containing the heading "Tellers for the Ayes"' do
    @division.content_teller_votes.size.should == 2
    @division.content_teller_votes[0].name.should == 'Waldegrave, E.'
    @division.content_teller_votes[1].name.should == 'Churchill, V.'
  end

  it 'should create teller not-content votes for the cells that appear below the cell containing the heading "Tellers for the Noes"' do
    @division.not_content_teller_votes.size.should == 2

    @division.not_content_teller_votes[0].name.should == 'Denman, L.'
    @division.not_content_teller_votes[1].name.should == 'Colebrooke, L.'
  end

  it 'should create correct number of content votes' do
    @division.content_votes.size.should == 94
    @division.content_teller_votes.size.should == 2
  end

end
