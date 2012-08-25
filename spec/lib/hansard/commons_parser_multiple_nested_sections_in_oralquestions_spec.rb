require File.dirname(__FILE__) + '/../../spec_helper'

describe Hansard::CommonsParser do
  before(:all) do
    file = 'housecommons_multiple_nested_sections_in_oralquestions.xml'
    @data_file = DataFile.new :name => file
    @sitting = parse_hansard_file Hansard::CommonsParser, data_file_path(file), @data_file
  end
  
  it 'should work' do
    @data_file.log.should == nil
  end

end
