require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::LordsParser do
  before(:all) do
    file = 'houselords_example_part_2.xml'
    @data_file = DataFile.new :name => file
    @sitting = parse_hansard_file Hansard::LordsParser, data_file_path(file), @data_file
  end

  it 'should work' do
    @data_file.log.should == nil
  end

  it 'should create a LordsReport Sitting type' do
    @sitting.should be_a_kind_of(HouseOfLordsReport)
  end

end
