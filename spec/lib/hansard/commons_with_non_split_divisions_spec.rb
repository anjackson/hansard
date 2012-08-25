require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser, 'when two whole division tables each follow house divided text' do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1995, 11, 6)
    @sitting_date_text = 'Monday 6 November 1995'
    @sitting_title = 'House of Commons'
    @sitting_start_column = '579'
    @sitting_end_column = '666'
    source_file = SourceFile.new
    file = 'housecommons_with_non_split_divisions.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), nil, source_file
    @sitting.save!
  end

  it_should_behave_like "All sittings"

  it 'should create division placeholder for division element that occurs after the first "The House divided" text' do
    @sitting.debates.sections.first.contributions[3].should be_an_instance_of(DivisionPlaceholder)
  end

  it 'should create division placeholder for division element that occurs after the second "The House divided" text' do
    @sitting.debates.sections.first.contributions[7].should be_an_instance_of(DivisionPlaceholder)
  end
end

