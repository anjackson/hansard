require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    @sitting_type = HouseOfCommonsSitting
    @sitting_date = Date.new(1968, 12, 4)
    @sitting_date_text = 'Wednesday, 4th December, 1968'
    @sitting_title = 'HOUSE OF COMMONS'
    @sitting_start_column = '1497'
    @sitting_end_column = '1709'
    @sitting_start_image = 'S5CV0774P0I0756'
    file = 'housecommons_whole_division_following_split_division.xml'
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), nil, SourceFile.new
    
    @sitting.save!
  end

  it_should_behave_like "All sittings"

end
