require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseLordsParser do
  before(:all) do
    file = 'houselords_example_part_2.xml'
    @data_file = DataFile.new :name => file
    @sitting = Hansard::HouseLordsParser.new(File.dirname(__FILE__) + "/../data/#{file}", @data_file).parse
    @sitting.save!
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it 'should work' do
    @data_file.log.should == nil
  end
  
  it "should set the part id correctly for the second sitting in a day" do
    @sitting.part_id.should == 2
  end

end
