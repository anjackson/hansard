require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser do
  before(:all) do
    file = 'housecommons_multiple_nested_sections_in_oralquestions.xml'
    @data_file = DataFile.new :name => file
    @sitting = Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../data/#{file}", @data_file).parse
    @sitting.save!
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it 'should work' do
    @data_file.log.should == nil
  end

end
