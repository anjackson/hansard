require File.dirname(__FILE__) + '/hansard_parser_spec_helper'

describe Hansard::HouseCommonsParser do

  before(:all) do
    DataFile.stub!(:log_to_stdout)
    file = 'housecommons_paras_without_ids.xml'
    @data_file = DataFile.new :name => file
    @sitting = Hansard::HouseCommonsParser.new(File.dirname(__FILE__) + "/../data/#{file}", @data_file).parse
    @sitting.save!
  end

  after(:all) do
    Sitting.find(:all).each {|s| s.destroy}
  end

  it "should write errors to the log for paragraphs without ids" do
    @data_file.log.should match(/procedural contribution without id: .*?\n MemberContribution without id:/)
  end
  
end
