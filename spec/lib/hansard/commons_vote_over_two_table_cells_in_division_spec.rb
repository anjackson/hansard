require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(2004, 9, 8)
    @sitting_date_text = 'Wednesday 8 September 2004'
    @sitting_title = 'House of Commons'
    @sitting_start_column = '701'
    @sitting_end_column = '830'
    file = 'housecommons_vote_over_two_table_cells_in_division.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), nil, mock_model(SourceFile, :volume => mock_model(Volume), :series_number=>5)

    @sitting.save!

    @first_section = @sitting.debates.sections.first
    @division_placeholder = @first_section.contributions[3]
    @division = @division_placeholder.division
  end
  
  it_should_behave_like "All sittings"

  it 'should ignore empty cells' do
    vote = @division.votes[16]
    vote.name.should == 'Bottomley, rh Virginia'
  end

  it 'should put constituency split across two cells on to one vote' do
    vote = @division.votes[20]
    vote.name.should == 'Kennedy, rh Charles'
    vote.constituency.should == 'Ross Skye & Inverness'
  end

  it 'should not create vote for end part of a constituency name' do
    vote = @division.votes[22]
    vote.name.should_not == 'Inverness)'
    vote.name.should == 'Brooke, Mrs Annette L.'
  end

  it 'should add constituency in its own cell to the vote above' do
    vote = @division.votes[180]
    vote.name.should == 'Winterton, Sir Nicholas'
    vote.constituency.should == 'Macclesfield'
  end

  it 'should note create vote for constituency on its own' do
    vote = @division.votes[182]
    vote.name.should == 'Trend, Michael'
  end

  it 'should create correct number of ayes votes' do
    @division.aye_votes.size.should == 190
  end

  it 'should create correct number of noes votes' do
    @division.noe_votes.size.should == 307
  end
end
